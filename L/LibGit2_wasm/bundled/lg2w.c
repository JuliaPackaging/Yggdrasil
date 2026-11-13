/*
 * lg2w: libgit2 1.9.7 as a standalone wasm32-wasip1 module with a flat API (route (a) of
 * STATUS.md), PCRE2_wasm-style: the caller copies NUL-terminated strings into this module's
 * memory (malloc + stores), calls an lg2w_* export, and copies the result out of the
 * "out buffer" (lg2w_out_ptr/lg2w_out_len). Every lg2w_* returns libgit2's code (< 0 an error,
 * then lg2w_error_class/lg2w_error_message), or a non-negative value documented per function.
 * A repository is an opaque handle (its git_repository* as an i32).
 *
 * The network: HTTP(S) smart protocol (fetch/clone/ls-remote, upload-pack only) through a
 * custom smart subtransport whose requests go to the host import
 *   wasm_host.http_request(req, req_len, res, res_cap) -> i32
 * of WasmHost.jl (protocol "wasm-fetch 1"): request/response bodies are files of the
 * WASI filesystem under $WASMHOST_SPOOL. The import may suspend (JSPI).
 *
 * Copyright (c) 2026; MIT (this file). libgit2 is GPL-2.0 WITH linking exception.
 */
#include <git2.h>
#include <git2/sys/transport.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>

#include <stdarg.h>
#include <git2/sys/errors.h>
#include <git2/sys/config.h>

#define EXPORT(name) __attribute__((export_name(#name))) name

/* the version of this module's interface (the lg2w_* functions and the raw exports in exports.txt) */
#define LG2W_ABI_VERSION 1

/* a growable byte buffer (libgit2's own is internal) */
typedef struct { char *ptr; size_t size, cap; } buf_t;
static int buf_put(buf_t *b, const void *p, size_t n) {
	if (b->size + n + 1 > b->cap) {
		size_t c = b->cap ? b->cap : 256;
		while (c < b->size + n + 1) c *= 2;
		char *q = realloc(b->ptr, c); if (!q) { git_error_set_oom(); return -1; }
		b->ptr = q; b->cap = c;
	}
	memcpy(b->ptr + b->size, p, n); b->size += n; b->ptr[b->size] = 0; return 0;
}
static int buf_printf(buf_t *b, const char *fmt, ...) {
	char tmp[8192]; int n; va_list ap;
	va_start(ap, fmt); n = vsnprintf(tmp, sizeof tmp, fmt, ap); va_end(ap);
	if (n < 0 || (size_t)n >= sizeof tmp) { git_error_set_str(GIT_ERROR_NET, "lg2w: request too long"); return -1; }
	return buf_put(b, tmp, (size_t)n);
}
static void buf_free(buf_t *b) { free(b->ptr); b->ptr = NULL; b->size = b->cap = 0; }

/* ---------- out buffer and errors ---------- */

static char *out_buf; static size_t out_len, out_cap;
static void out_reset(void) { out_len = 0; if (out_buf) out_buf[0] = 0; }
static int out_put(const void *p, size_t n) {
	if (out_len + n + 1 > out_cap) {
		size_t c = out_cap ? out_cap : 4096;
		while (c < out_len + n + 1) c *= 2;
		char *b = realloc(out_buf, c); if (!b) return -1;
		out_buf = b; out_cap = c;
	}
	memcpy(out_buf + out_len, p, n); out_len += n; out_buf[out_len] = 0; return 0;
}
static int out_str(const char *s) { return out_put(s, strlen(s)); }
static int out_oid(const git_oid *id) { char h[GIT_OID_MAX_HEXSIZE + 1]; git_oid_tostr(h, sizeof h, id); return out_str(h); }

uint32_t EXPORT(lg2w_out_ptr)(void) { return (uint32_t)(uintptr_t)out_buf; }
uint32_t EXPORT(lg2w_out_len)(void) { return (uint32_t)out_len; }

static int err_class; static char err_msg[1024];
static int fail(int code) {
	const git_error *e = git_error_last();
	err_class = e ? e->klass : 0;
	snprintf(err_msg, sizeof err_msg, "%s", e && e->message ? e->message : "");
	return code;
}
#define TRY(x) do { int _e = (x); if (_e < 0) { rc = fail(_e); goto done; } } while (0)
int EXPORT(lg2w_error_class)(void) { return err_class; }
uint32_t EXPORT(lg2w_error_message)(void) { return (uint32_t)(uintptr_t)err_msg; }

/* loads/stores by address, for a caller that can't reach this memory (another Wasm module) */
uint32_t EXPORT(mem_load8)(uint32_t a) { return *(uint8_t *)(uintptr_t)a; }
uint32_t EXPORT(mem_load32)(uint32_t a) { uint32_t v; memcpy(&v, (void *)(uintptr_t)a, 4); return v; }
uint64_t EXPORT(mem_load64)(uint32_t a) { uint64_t v; memcpy(&v, (void *)(uintptr_t)a, 8); return v; }
void EXPORT(mem_store8)(uint32_t a, uint32_t v) { *(uint8_t *)(uintptr_t)a = (uint8_t)v; }
void EXPORT(mem_store32)(uint32_t a, uint32_t v) { memcpy((void *)(uintptr_t)a, &v, 4); }
void EXPORT(mem_store64)(uint32_t a, uint64_t v) { memcpy((void *)(uintptr_t)a, &v, 8); }

static git_repository *R(uint32_t h) { return (git_repository *)(uintptr_t)h; }
static const char *opt(const char *s) { return s && *s ? s : NULL; }

/* ---------- the host's HTTP: WasmHost's "wasm-fetch 1" ---------- */

__attribute__((import_module("wasm_host"), import_name("http_request")))
int32_t wasm_host_http_request(const char *req, int32_t req_len, char *res, int32_t res_cap);

typedef struct { int code; int status; char ctype[128]; char url[2048]; char message[512]; } http_result;

static unsigned spool_counter, spool_nonce;
static int spool_path(char *buf, size_t n, const char *suffix) {
	const char *sp = getenv("WASMHOST_SPOOL");
	if (!sp || !*sp) { git_error_set_str(GIT_ERROR_NET, "lg2w: the host provides no fetch (WASMHOST_SPOOL is not set)"); return -1; }
	/* (unique per instance: instances sharing a spool directory have different nonces) */
	while (!spool_nonce && getentropy(&spool_nonce, sizeof spool_nonce) == 0) {}
	snprintf(buf, n, "%s/lg2w-%08x-%u%s", sp, spool_nonce, ++spool_counter, suffix);
	return 0;
}

static const char *next_line(const char *p, const char *end, char *dst, size_t n) {
	size_t i = 0;
	while (p < end && *p != '\n') { if (i + 1 < n) dst[i++] = *p; p++; }
	dst[i] = 0; return p < end ? p + 1 : p;
}

/* one request through the host: body (may be NULL) from `in`, response body into `out` */
static int host_request(http_result *r, const char *method, const char *url, const char *headers,
                        const char *in, const char *out) {
	buf_t req = {0};
	char *res = NULL; int n, cap = 64 * 1024, rc = -1;
	if (strchr(url, '\n')) { git_error_set_str(GIT_ERROR_NET, "lg2w: line break in URL"); return -1; }
	if (buf_printf(&req, "wasm-fetch 1\n%s\n%s\n%s\n%s\ninf\n%s", method, url, out ? out : "", in ? in : "", headers) < 0) return -1;
	res = malloc(cap); if (!res) goto done;
	n = wasm_host_http_request(req.ptr, (int32_t)req.size, res, cap);
	if (n < 0) { git_error_set(GIT_ERROR_NET, "lg2w: host response of %d bytes exceeds %d", -n, cap); goto done; }
	{
		const char *p = res, *e = res + n; char line[2048];
		memset(r, 0, sizeof *r);
		p = next_line(p, e, line, sizeof line);
		if (strcmp(line, "wasm-fetch 1")) { git_error_set_str(GIT_ERROR_NET, "lg2w: malformed host response"); goto done; }
		p = next_line(p, e, line, sizeof line); r->code = atoi(line);
		p = next_line(p, e, r->message, sizeof r->message);
		p = next_line(p, e, r->url, sizeof r->url);
		p = next_line(p, e, line, sizeof line); r->status = atoi(line);
		p = next_line(p, e, line, sizeof line);                     /* status line */
		while (p < e) {
			p = next_line(p, e, line, sizeof line);
			if (!strncasecmp(line, "content-type:", 13)) {
				const char *v = line + 13; while (*v == ' ') v++;
				snprintf(r->ctype, sizeof r->ctype, "%s", v);
			}
		}
	}
	if (r->code) { git_error_set(GIT_ERROR_NET, "lg2w: request to '%s' failed: %s (curl code %d)", url, r->message, r->code); goto done; }
	rc = 0;
done:
	free(res); buf_free(&req);
	return rc;
}

/* ---------- the smart subtransport ---------- */

typedef struct {
	git_smart_subtransport parent;
	git_transport *owner;
	char base[2048];                    /* the repository URL, after the redirects of info/refs */
} host_subtransport;

typedef struct {
	git_smart_subtransport_stream parent;
	git_smart_service_t service;
	char url[2048];
	buf_t body;                         /* the POST body written by the smart protocol */
	FILE *res;                          /* the response body, once requested */
	char res_path[512];
} host_stream;

static int stream_request(host_stream *s) {
	host_subtransport *t = (host_subtransport *)s->parent.subtransport;
	char in_path[512] = "", hdrs[512]; http_result r; int post = s->service == GIT_SERVICE_UPLOADPACK, rc = -1;
	const char *expect = post ? "application/x-git-upload-pack-result" : "application/x-git-upload-pack-advertisement";
	if (spool_path(s->res_path, sizeof s->res_path, ".res") < 0) return -1;
	snprintf(hdrs, sizeof hdrs, "User-Agent: git/2.0 (libgit2 " LIBGIT2_VERSION "; lg2w)\n%s",
	         post ? "Content-Type: application/x-git-upload-pack-request\nAccept: application/x-git-upload-pack-result\n" : "");
	if (post) {
		FILE *f;
		if (spool_path(in_path, sizeof in_path, ".req-body") < 0) return -1;
		if (!(f = fopen(in_path, "wb")) || fwrite(s->body.ptr, 1, s->body.size, f) != s->body.size) {
			if (f) fclose(f);
			git_error_set(GIT_ERROR_OS, "lg2w: could not write '%s'", in_path); return -1;
		}
		fclose(f);
	}
	if (host_request(&r, post ? "POST" : "GET", s->url, hdrs, post ? in_path : NULL, s->res_path) < 0) goto done;
	if (r.status == 401 || r.status == 407) {   /* as libgit2's http.c with no credentials callback */
		git_error_set(GIT_ERROR_HTTP, "%s authentication required but no callback set", r.status == 401 ? "remote" : "proxy");
		rc = GIT_EAUTH; goto done;
	}
	if (r.status != 200) { git_error_set(GIT_ERROR_HTTP, "unexpected http status code: %d", r.status); goto done; }
	if (strncmp(r.ctype, expect, strlen(expect))) {
		git_error_set(GIT_ERROR_HTTP, "invalid content-type: '%s' (not a smart HTTP server?)", r.ctype); goto done;
	}
	if (!post) {                         /* follow a redirect of info/refs for the POSTs */
		const char *suf = "/info/refs?service=git-upload-pack";
		size_t ul = strlen(r.url), sl = strlen(suf);
		if (ul > sl && !strcmp(r.url + ul - sl, suf) && ul - sl < sizeof t->base) {
			memcpy(t->base, r.url, ul - sl); t->base[ul - sl] = 0;
		}
	}
	if (!(s->res = fopen(s->res_path, "rb"))) { git_error_set(GIT_ERROR_OS, "lg2w: could not open '%s'", s->res_path); goto done; }
	rc = 0;
done:
	if (*in_path) unlink(in_path);
	return rc;
}

static int stream_read(git_smart_subtransport_stream *st, char *buf, size_t n, size_t *got) {
	host_stream *s = (host_stream *)st;
	*got = 0;
	int rc;
	if (!s->res && (rc = stream_request(s)) < 0) return rc;
	*got = fread(buf, 1, n, s->res);
	if (*got == 0 && ferror(s->res)) { git_error_set_str(GIT_ERROR_OS, "lg2w: read error"); return -1; }
	return 0;
}

static int stream_write(git_smart_subtransport_stream *st, const char *buf, size_t n) {
	host_stream *s = (host_stream *)st;
	if (s->service != GIT_SERVICE_UPLOADPACK || s->res) { git_error_set_str(GIT_ERROR_NET, "lg2w: write on a read stream"); return -1; }
	return buf_put(&s->body, buf, n);
}

static void stream_free(git_smart_subtransport_stream *st) {
	host_stream *s = (host_stream *)st;
	if (s->res) { fclose(s->res); unlink(s->res_path); }
	buf_free(&s->body); free(s);
}

static int sub_action(git_smart_subtransport_stream **out, git_smart_subtransport *sub, const char *url, git_smart_service_t action) {
	host_subtransport *t = (host_subtransport *)sub;
	host_stream *s;
	if (action != GIT_SERVICE_UPLOADPACK_LS && action != GIT_SERVICE_UPLOADPACK) {
		git_error_set_str(GIT_ERROR_NET, "lg2w: push (receive-pack) is not supported"); return -1;
	}
	if (action == GIT_SERVICE_UPLOADPACK_LS || !*t->base) {
		size_t n = strlen(url);
		while (n && url[n - 1] == '/') n--;
		if (n >= sizeof t->base) { git_error_set_str(GIT_ERROR_NET, "lg2w: URL too long"); return -1; }
		memcpy(t->base, url, n); t->base[n] = 0;
	}
	if (!(s = calloc(1, sizeof *s))) return -1;
	s->parent.subtransport = sub;
	s->parent.read = stream_read; s->parent.write = stream_write; s->parent.free = stream_free;
	s->service = action;
	snprintf(s->url, sizeof s->url, "%s%s", t->base,
	         action == GIT_SERVICE_UPLOADPACK_LS ? "/info/refs?service=git-upload-pack" : "/git-upload-pack");
	*out = &s->parent;
	return 0;
}
static int sub_close(git_smart_subtransport *sub) { (void)sub; return 0; }
static void sub_free(git_smart_subtransport *sub) { free(sub); }

static int sub_new(git_smart_subtransport **out, git_transport *owner, void *param) {
	host_subtransport *t = calloc(1, sizeof *t);
	(void)param;
	if (!t) return -1;
	t->owner = owner;
	t->parent.action = sub_action; t->parent.close = sub_close; t->parent.free = sub_free;
	*out = &t->parent;
	return 0;
}
static git_smart_subtransport_definition host_http = { sub_new, 1 /* stateless RPC */, NULL };
static int transport_cb(git_transport **out, git_remote *owner, void *param) {
	(void)param;
	return git_transport_smart(out, owner, &host_http);
}

/* ---------- init ---------- */

int EXPORT(lg2w_init)(void) {
	int rc = git_libgit2_init();
	if (rc < 0) return fail(rc);
	if (rc == 1) {                      /* first init: our transport for http(s) */
		if ((rc = git_transport_register("https", transport_cb, NULL)) < 0 ||
		    (rc = git_transport_register("http", transport_cb, NULL)) < 0)
			return fail(rc);
	}
	return 0;
}
uint32_t EXPORT(lg2w_abi_version)(void) { return LG2W_ABI_VERSION; }
uint32_t EXPORT(lg2w_version)(void) { return LIBGIT2_VER_MAJOR * 10000 + LIBGIT2_VER_MINOR * 100 + LIBGIT2_VER_REVISION; }

/* ---------- repositories ---------- */

/* WASI preview 1 has no permission bits: every file reads as non-executable. As on any
   filesystem without them, take core.filemode = false (an in-memory app-level config,
   above the repository's own), so a repository git made with executables is not dirty. */
static int wasi_overrides(git_repository *r) {
	static const char cfg[] = "[core]\n\tfilemode = false\n";
	git_config *c = NULL; git_config_backend *b = NULL; int rc;
	if ((rc = git_repository_config(&c, r)) < 0) return rc;
	if ((rc = git_config_backend_from_string(&b, cfg, sizeof cfg - 1, NULL)) == 0 &&
	    (rc = git_config_add_backend(c, b, GIT_CONFIG_LEVEL_APP, r, 1)) < 0)
		b->free(b);
	git_config_free(c);
	return rc;
}
static int repo_handle(git_repository *r, int rc) {
	if (rc == 0 && (rc = wasi_overrides(r)) < 0) git_repository_free(r);
	return rc < 0 ? fail(rc) : (int)(uintptr_t)r;
}

/* `git_repository_open`: a handle (> 0) */
int EXPORT(lg2w_open)(const char *path) {
	git_repository *r = NULL; int rc = git_repository_open(&r, path);
	return repo_handle(r, rc);
}
int EXPORT(lg2w_init_repo)(const char *path, int bare) {
	git_repository *r = NULL; int rc = git_repository_init(&r, path, (unsigned)bare);
	return repo_handle(r, rc);
}
void EXPORT(lg2w_close)(uint32_t repo) { git_repository_free(R(repo)); }

/* bit 0 bare, bit 1 shallow, bit 2 HEAD detached, bit 3 HEAD unborn; out: gitdir "\n" workdir */
int EXPORT(lg2w_repo_info)(uint32_t repo) {
	git_repository *r = R(repo); int f = 0, d;
	out_reset();
	f |= git_repository_is_bare(r) ? 1 : 0;
	f |= git_repository_is_shallow(r) == 1 ? 2 : 0;
	d = git_repository_head_detached(r); f |= d == 1 ? 4 : 0;
	f |= git_repository_head_unborn(r) == 1 ? 8 : 0;
	out_str(git_repository_path(r)); out_str("\n");
	if (git_repository_workdir(r)) out_str(git_repository_workdir(r));
	return f;
}

/* HEAD: out = oid "\n" ref name (as LibGit2.head + headname); returns 1 if attached, 0 if detached */
int EXPORT(lg2w_head)(uint32_t repo) {
	git_reference *h = NULL; int rc;
	out_reset();
	TRY(git_repository_head(&h, R(repo)));
	out_oid(git_reference_target(h)); out_str("\n"); out_str(git_reference_name(h));
	rc = !git_repository_head_detached(R(repo));
done:
	git_reference_free(h); return rc;
}

/* ---------- objects ---------- */

/* `git_revparse_single`: returns the object's type (GIT_OBJECT_*), out = its oid */
int EXPORT(lg2w_revparse)(uint32_t repo, const char *spec) {
	git_object *o = NULL; int rc;
	out_reset();
	TRY(git_revparse_single(&o, R(repo), spec));
	out_oid(git_object_id(o)); rc = git_object_type(o);
done:
	git_object_free(o); return rc;
}

/* `git_object_peel` of the object `hex` to `type`: returns the type, out = oid */
int EXPORT(lg2w_peel)(uint32_t repo, const char *hex, int type) {
	git_object *o = NULL, *p = NULL; git_oid id; int rc;
	out_reset();
	TRY(git_oid_fromstr(&id, hex));
	TRY(git_object_lookup(&o, R(repo), &id, GIT_OBJECT_ANY));
	TRY(git_object_peel(&p, o, (git_object_t)type));
	out_oid(git_object_id(p)); rc = git_object_type(p);
done:
	git_object_free(p); git_object_free(o); return rc;
}

/* the entry `path` of tree `hex` (`getindex(::GitTree, path)`): returns its type, out = oid */
int EXPORT(lg2w_tree_entry)(uint32_t repo, const char *hex, const char *path) {
	git_tree *t = NULL; git_tree_entry *e = NULL; git_oid id; int rc;
	out_reset();
	TRY(git_oid_fromstr(&id, hex));
	TRY(git_tree_lookup(&t, R(repo), &id));
	TRY(git_tree_entry_bypath(&e, t, path));
	out_oid(git_tree_entry_id(e)); rc = git_tree_entry_type(e);
done:
	git_tree_entry_free(e); git_tree_free(t); return rc;
}

/* the raw content of object `hex` (blob bytes, or a commit/tree/tag's encoding): returns its type */
int EXPORT(lg2w_read)(uint32_t repo, const char *hex) {
	git_odb *db = NULL; git_odb_object *o = NULL; git_oid id; int rc;
	out_reset();
	TRY(git_oid_fromstr(&id, hex));
	TRY(git_repository_odb(&db, R(repo)));
	TRY(git_odb_read(&o, db, &id));
	if (out_put(git_odb_object_data(o), git_odb_object_size(o)) < 0) { rc = -1; goto done; }
	rc = git_odb_object_type(o);
done:
	git_odb_object_free(o); git_odb_free(db); return rc;
}

static int ls_cb(const char *root, const git_tree_entry *e, void *p) {
	char m[16]; (void)p;
	snprintf(m, sizeof m, "%06o ", git_tree_entry_filemode(e));
	out_str(m); out_str(git_object_type2string(git_tree_entry_type(e))); out_str(" ");
	out_oid(git_tree_entry_id(e)); out_str("\t"); out_str(root); out_str(git_tree_entry_name(e)); out_put("", 1);
	return 0;
}
/* `git ls-tree -r -t -z` of a tree-ish: out = "<mode> <type> <oid>\t<path>\0"...; returns the count */
int EXPORT(lg2w_ls_tree)(uint32_t repo, const char *spec) {
	git_object *o = NULL; git_tree *t = NULL; int rc;
	out_reset();
	TRY(git_revparse_single(&o, R(repo), spec));
	TRY(git_object_peel((git_object **)&t, o, GIT_OBJECT_TREE));
	TRY(git_tree_walk(t, GIT_TREEWALK_PRE, ls_cb, NULL));
	rc = 0;
done:
	git_tree_free(t); git_object_free(o); return rc;
}

/* ---------- refs, remotes, config ---------- */

/* out = "<oid> <name>\n" for each reference (symbolic ones resolved) */
int EXPORT(lg2w_refs)(uint32_t repo) {
	git_reference_iterator *it = NULL; git_reference *ref, *res; int rc, n = 0;
	out_reset();
	TRY(git_reference_iterator_new(&it, R(repo)));
	while ((rc = git_reference_next(&ref, it)) == 0) {
		if (git_reference_resolve(&res, ref) == 0) {
			out_oid(git_reference_target(res)); out_str(" "); out_str(git_reference_name(ref)); out_str("\n");
			git_reference_free(res); n++;
		}
		git_reference_free(ref);
	}
	rc = rc == GIT_ITEROVER ? n : fail(rc);
done:
	git_reference_iterator_free(it); return rc;
}

int EXPORT(lg2w_remotes)(uint32_t repo) {
	git_strarray a = {0}; int rc; size_t i;
	out_reset();
	TRY(git_remote_list(&a, R(repo)));
	for (i = 0; i < a.count; i++) { out_str(a.strings[i]); out_str("\n"); }
	rc = (int)a.count;
done:
	git_strarray_dispose(&a); return rc;
}

int EXPORT(lg2w_remote_url)(uint32_t repo, const char *name) {
	git_remote *rm = NULL; int rc;
	out_reset();
	TRY(git_remote_lookup(&rm, R(repo), name));
	out_str(git_remote_url(rm)); rc = 0;
done:
	git_remote_free(rm); return rc;
}

/* a configuration value: of the repository, or (repo = 0) the default global/system one */
int EXPORT(lg2w_config_get)(uint32_t repo, const char *name) {
	git_config *c = NULL, *snap = NULL; const char *v; int rc;
	out_reset();
	TRY(repo ? git_repository_config(&c, R(repo)) : git_config_open_default(&c));
	TRY(git_config_snapshot(&snap, c));
	TRY(git_config_get_string(&v, snap, name));
	out_str(v); rc = 0;
done:
	git_config_free(snap); git_config_free(c); return rc;
}

/* ---------- work tree ---------- */

/* LibGit2.isdirty: HEAD's tree vs. the work tree with the index; 1 if any change */
int EXPORT(lg2w_isdirty)(uint32_t repo) {
	git_object *o = NULL; git_tree *t = NULL; git_diff *d = NULL; int rc;
	git_diff_options opts = GIT_DIFF_OPTIONS_INIT;
	TRY(git_revparse_single(&o, R(repo), "HEAD^{tree}"));
	t = (git_tree *)o; o = NULL;
	TRY(git_diff_tree_to_workdir_with_index(&d, R(repo), t, &opts));
	rc = git_diff_num_deltas(d) > 0;
done:
	git_diff_free(d); git_tree_free(t); return rc;
}

/* checkout_tree with CHECKOUT_FORCE (into `target_dir`, or the work tree if empty) */
int EXPORT(lg2w_checkout_tree)(uint32_t repo, const char *spec, const char *target_dir) {
	git_object *o = NULL; int rc;
	git_checkout_options co = GIT_CHECKOUT_OPTIONS_INIT;
	co.checkout_strategy = GIT_CHECKOUT_FORCE;
	co.target_directory = opt(target_dir);
	TRY(git_revparse_single(&o, R(repo), spec));
	TRY(git_checkout_tree(R(repo), o, &co));
	rc = 0;
done:
	git_object_free(o); return rc;
}

/* reset! (mode 1 soft, 2 mixed, 3 hard) to the commit `spec` */
int EXPORT(lg2w_reset)(uint32_t repo, const char *spec, int mode) {
	git_object *o = NULL; int rc;
	TRY(git_revparse_single(&o, R(repo), spec));
	TRY(git_reset(R(repo), o, (git_reset_t)mode, NULL));
	rc = 0;
done:
	git_object_free(o); return rc;
}

/* stage everything (`git add -A`) and commit on HEAD; out = the new commit's oid */
int EXPORT(lg2w_commit_all)(uint32_t repo, const char *message, const char *name, const char *email) {
	git_index *ix = NULL; git_oid tree_id, cid; git_tree *tree = NULL; git_signature *sig = NULL;
	git_object *parent = NULL; git_strarray all = {0}; int rc, np = 0;
	char *star = "*"; all.strings = &star; all.count = 1;
	out_reset();
	TRY(git_repository_index(&ix, R(repo)));
	TRY(git_index_add_all(ix, &all, GIT_INDEX_ADD_DEFAULT, NULL, NULL));
	TRY(git_index_update_all(ix, &all, NULL, NULL));
	TRY(git_index_write(ix));
	TRY(git_index_write_tree(&tree_id, ix));
	TRY(git_tree_lookup(&tree, R(repo), &tree_id));
	TRY(git_signature_now(&sig, name, email));
	rc = git_revparse_single(&parent, R(repo), "HEAD^{commit}");
	if (rc == 0) np = 1; else if (rc != GIT_ENOTFOUND) { rc = fail(rc); goto done; }
	TRY(git_commit_create_v(&cid, R(repo), "HEAD", sig, sig, NULL, message, tree, np, parent));
	out_oid(&cid); rc = 0;
done:
	git_object_free(parent); git_signature_free(sig); git_tree_free(tree); git_index_free(ix); return rc;
}

/* ---------- network ---------- */

/* clone `url` into `path` (bare if `bare`; branch may be empty; depth 0 = full): a handle */
int EXPORT(lg2w_clone)(const char *url, const char *path, int bare, const char *branch, int depth) {
	git_repository *r = NULL; int rc;
	git_clone_options o = GIT_CLONE_OPTIONS_INIT;
	o.bare = bare; o.checkout_branch = opt(branch); o.fetch_opts.depth = depth;
	o.fetch_opts.download_tags = GIT_REMOTE_DOWNLOAD_TAGS_AUTO;   /* as Julia's FetchOptions */
	rc = git_clone(&r, url, path, &o);
	return repo_handle(r, rc);
}

/* fetch from remote `remote` (a name, or a URL for an anonymous remote) with refspecs
   (newline-separated, empty: the remote's own) and depth (0 full, 2147483647 unshallow) */
int EXPORT(lg2w_fetch)(uint32_t repo, const char *remote, const char *refspecs, int depth) {
	git_remote *rm = NULL; git_fetch_options fo = GIT_FETCH_OPTIONS_INIT;
	git_strarray specs = {0}; char *copy = NULL, *p, *save = NULL, *list[64]; int rc;
	if (git_remote_lookup(&rm, R(repo), remote) < 0) {
		git_error_clear();
		TRY(git_remote_create_anonymous(&rm, R(repo), remote));
	}
	if (opt(refspecs)) {
		copy = strdup(refspecs);
		for (p = strtok_r(copy, "\n", &save); p && specs.count < 64; p = strtok_r(NULL, "\n", &save))
			list[specs.count++] = p;
		specs.strings = list;
	}
	fo.update_fetchhead = 1; fo.depth = depth; fo.download_tags = GIT_REMOTE_DOWNLOAD_TAGS_AUTO;   /* 2147483647 = GIT_FETCH_DEPTH_UNSHALLOW */
	TRY(git_remote_fetch(rm, specs.count ? &specs : NULL, &fo, NULL));
	rc = 0;
done:
	free(copy); git_remote_free(rm); return rc;
}

/* `git ls-remote url`: out = "<oid>\t<name>\n"...; returns the count */
int EXPORT(lg2w_ls_remote)(const char *url) {
	git_remote *rm = NULL; const git_remote_head **heads; size_t n, i; int rc;
	out_reset();
	TRY(git_remote_create_detached(&rm, url));
	TRY(git_remote_connect(rm, GIT_DIRECTION_FETCH, NULL, NULL, NULL));
	TRY(git_remote_ls(&heads, &n, rm));
	for (i = 0; i < n; i++) { out_oid(&heads[i]->oid); out_str("\t"); out_str(heads[i]->name); out_str("\n"); }
	rc = (int)n;
done:
	git_remote_free(rm); return rc;
}

/* ---------- the raw API, for a caller that implements libgit2's C API over this module ----------
   (WasmCompat's LibGit2 backend: Julia's LibGit2 stdlib, its ccalls routed here). These take what
   the raw functions take, with option structs flattened to their scalar fields (the caller has
   them in its own memory) and the WASI defaults applied as lg2w_open does. Out-handles are
   addresses of 4-byte slots in this memory. */

int EXPORT(lg2w_repository_open)(git_repository **out, const char *path) {
	int rc = git_repository_open(out, path);
	if (rc == 0 && (rc = wasi_overrides(*out)) < 0) { git_repository_free(*out); *out = NULL; }
	return rc;
}
int EXPORT(lg2w_repository_init)(git_repository **out, const char *path, unsigned bare) {
	int rc = git_repository_init(out, path, bare);
	if (rc == 0 && (rc = wasi_overrides(*out)) < 0) { git_repository_free(*out); *out = NULL; }
	return rc;
}

static void fetch_opts(git_fetch_options *fo, int prune, int update_fetchhead, int download_tags, int depth,
                       int follow_redirects) {
	fo->prune = prune; fo->update_fetchhead = update_fetchhead; fo->download_tags = download_tags;
	fo->depth = depth; fo->follow_redirects = follow_redirects;
}

/* git_clone with git_clone_options' scalar fields (callbacks and payloads are the caller's: none here) */
int EXPORT(lg2w_clone_raw)(git_repository **out, const char *url, const char *path, int bare,
                           const char *checkout_branch, unsigned checkout_strategy,
                           int prune, int update_fetchhead, int download_tags, int depth, int follow_redirects) {
	git_clone_options o = GIT_CLONE_OPTIONS_INIT;
	int rc;
	o.bare = bare; o.checkout_branch = checkout_branch;
	o.checkout_opts.checkout_strategy = checkout_strategy;
	fetch_opts(&o.fetch_opts, prune, update_fetchhead, download_tags, depth, follow_redirects);
	rc = git_clone(out, url, path, &o);
	if (rc == 0 && (rc = wasi_overrides(*out)) < 0) { git_repository_free(*out); *out = NULL; }
	return rc;
}

/* git_remote_fetch with git_fetch_options' scalar fields; refspecs a git_strarray in this memory or NULL */
int EXPORT(lg2w_remote_fetch_raw)(git_remote *remote, const git_strarray *refspecs, const char *reflog_message,
                                  int prune, int update_fetchhead, int download_tags, int depth, int follow_redirects) {
	git_fetch_options fo = GIT_FETCH_OPTIONS_INIT;
	fetch_opts(&fo, prune, update_fetchhead, download_tags, depth, follow_redirects);
	return git_remote_fetch(remote, refspecs, &fo, reflog_message);
}

static void checkout_opts(git_checkout_options *co, unsigned strategy, int disable_filters, unsigned dir_mode,
                          unsigned file_mode, int file_open_flags, unsigned notify_flags, const git_strarray *paths,
                          const char *target_directory, const char *ancestor_label, const char *our_label,
                          const char *their_label) {
	co->checkout_strategy = strategy; co->disable_filters = disable_filters; co->dir_mode = dir_mode;
	co->file_mode = file_mode; co->file_open_flags = file_open_flags; co->notify_flags = notify_flags;
	if (paths) co->paths = *paths;
	co->target_directory = target_directory; co->ancestor_label = ancestor_label;
	co->our_label = our_label; co->their_label = their_label;
}

/* git_checkout_tree / git_reset with git_checkout_options' scalar fields (no callbacks, baseline or perfdata) */
int EXPORT(lg2w_checkout_tree_raw)(git_repository *repo, const git_object *treeish, unsigned strategy,
                                   int disable_filters, unsigned dir_mode, unsigned file_mode, int file_open_flags,
                                   unsigned notify_flags, const git_strarray *paths, const char *target_directory,
                                   const char *ancestor_label, const char *our_label, const char *their_label) {
	git_checkout_options co = GIT_CHECKOUT_OPTIONS_INIT;
	checkout_opts(&co, strategy, disable_filters, dir_mode, file_mode, file_open_flags, notify_flags, paths,
	              target_directory, ancestor_label, our_label, their_label);
	return git_checkout_tree(repo, treeish, &co);
}
int EXPORT(lg2w_reset_raw)(git_repository *repo, const git_object *target, int reset_type, unsigned strategy,
                           int disable_filters, unsigned dir_mode, unsigned file_mode, int file_open_flags,
                           unsigned notify_flags, const git_strarray *paths, const char *target_directory,
                           const char *ancestor_label, const char *our_label, const char *their_label) {
	git_checkout_options co = GIT_CHECKOUT_OPTIONS_INIT;
	checkout_opts(&co, strategy, disable_filters, dir_mode, file_mode, file_open_flags, notify_flags, paths,
	              target_directory, ancestor_label, our_label, their_label);
	return git_reset(repo, target, (git_reset_t)reset_type, &co);
}

/* git_rebase_init with git_rebase_options' scalar fields (default merge and checkout options) */
int EXPORT(lg2w_rebase_init_raw)(git_rebase **out, git_repository *repo, const git_annotated_commit *branch,
                                 const git_annotated_commit *upstream, const git_annotated_commit *onto,
                                 int quiet, int inmemory, const char *rewrite_notes_ref) {
	git_rebase_options ro = GIT_REBASE_OPTIONS_INIT;
	ro.quiet = quiet; ro.inmemory = inmemory; ro.rewrite_notes_ref = rewrite_notes_ref;
	return git_rebase_init(out, repo, branch, upstream, onto, &ro);
}

/* git_libgit2_init and this module's transports (what Julia's LibGit2.initialize reaches) */
int EXPORT(lg2w_libgit2_init)(void) {
	int rc = git_libgit2_init();
	if (rc == 1 && (git_transport_register("https", transport_cb, NULL) < 0 ||
	                git_transport_register("http", transport_cb, NULL) < 0))
		return -1;
	return rc;
}
