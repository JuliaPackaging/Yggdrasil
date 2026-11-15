// All symbols use the `mgjl_` prefix so they can never collide with upstream Mongoose additions.

#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#include "mongoose.h"

// --- Manager ---

// Allocate and initialise a manager; free it with mgjl_mgr_free().
struct mg_mgr *mgjl_mgr_new(void) {
  struct mg_mgr *mgr = (struct mg_mgr *) calloc(1, sizeof(*mgr));
  if (mgr != NULL) mg_mgr_init(mgr);
  return mgr;
}

// Tear down a manager allocated by mgjl_mgr_new().
void mgjl_mgr_free(struct mg_mgr *mgr) {
  if (mgr != NULL) {
    mg_mgr_free(mgr);
    free(mgr);
  }
}

// --- Connection ---

// c->fn_data; NULL when c is NULL.
void *mgjl_conn_get_fn_data(struct mg_connection *c) {
  return c == NULL ? NULL : c->fn_data;
}

// Peer IP (no port), NUL-terminated in buf.
int mgjl_conn_get_remote_ip(const struct mg_connection *c, char *buf,
                            size_t len) {
  const uint8_t *p;
  if (c == NULL || buf == NULL || len == 0) return 0;
  p = c->rem.addr.ip;
  if (c->rem.is_ip6) {
    const uint16_t *g = (const uint16_t *) p;
    mg_snprintf(buf, len, "%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x",
                mg_ntohs(g[0]), mg_ntohs(g[1]), mg_ntohs(g[2]), mg_ntohs(g[3]),
                mg_ntohs(g[4]), mg_ntohs(g[5]), mg_ntohs(g[6]), mg_ntohs(g[7]));
  } else {
    mg_snprintf(buf, len, "%d.%d.%d.%d", p[0], p[1], p[2], p[3]);
  }
  return (int) strlen(buf);
}

// c->send.len: bytes queued but not yet accepted by the socket.
size_t mgjl_conn_send_len(const struct mg_connection *c) {
  return c == NULL ? 0 : c->send.len;
}

// Non-variadic mg_error() for FFI callers.
void mgjl_conn_error(struct mg_connection *c, const char *msg) {
  if (c != NULL) mg_error(c, "%s", msg == NULL ? "" : msg);
}

// Flush the send buffer, then close the connection (c->is_draining = 1).
void mgjl_conn_close_after_send(struct mg_connection *c) {
  if (c != NULL) c->is_draining = 1;
}

// --- HTTP ---

static size_t mgjl_print_raw(mg_pfn_t fn, void *arg, va_list *ap) {
  const char *buf = va_arg(*ap, const char *);
  size_t len = va_arg(*ap, size_t);
  struct mg_iobuf *io = (struct mg_iobuf *) arg;
  (void) fn;
  if (buf == NULL || len == 0) return 0;
  return mg_iobuf_add(io, io->len, buf, len);
}

// Binary-safe mg_http_reply(): body may contain NUL bytes and may be NULL
// when len == 0. The body is copied straight into c->send, bypassing printf.
void mgjl_http_reply_bin(struct mg_connection *c, int code, const char *headers,
                         const void *body, size_t len) {
  mg_http_reply(c, code, headers, "%M", mgjl_print_raw, (const char *) body,
                len);
}

// mg_http_serve_dir() with only root_dir set (mongoose defaults for the rest).
void mgjl_http_serve_dir(struct mg_connection *c, struct mg_http_message *hm,
                         const char *root_dir) {
  struct mg_http_serve_opts opts;
  memset(&opts, 0, sizeof(opts));
  opts.root_dir = root_dir;
  mg_http_serve_dir(c, hm, &opts);
}

// --- WebSocket ---

// Send a CLOSE frame (optional RFC 6455 status code + reason, truncated to
// the 125-byte control-frame limit) and drain the connection.
void mgjl_ws_close(struct mg_connection *c, int code, const char *reason) {
  uint8_t buf[125];
  size_t n = 0, rl;
  if (c == NULL) return;
  if (code != 0) {
    buf[n++] = (uint8_t) ((code >> 8) & 0xff);
    buf[n++] = (uint8_t) (code & 0xff);
  }
  if (reason != NULL) {
    rl = strlen(reason);
    if (rl > sizeof(buf) - n) rl = sizeof(buf) - n;
    memcpy(buf + n, reason, rl);
    n += rl;
  }
  mg_ws_send(c, buf, n, WEBSOCKET_OP_CLOSE);
  c->is_draining = 1;
}

// --- TLS ---

// mg_tls_init() from in-memory PEM/DER blobs (NULL pointer = empty field).
void mgjl_tls_init_mem(struct mg_connection *c,
                       const void *ca, size_t ca_len,
                       const void *cert, size_t cert_len,
                       const void *key, size_t key_len,
                       const void *name, size_t name_len,
                       int skip_verification) {
  struct mg_tls_opts opts;
  if (c == NULL) return;
  memset(&opts, 0, sizeof(opts));
  opts.ca = mg_str_n((const char *) ca, ca == NULL ? 0 : ca_len);
  opts.cert = mg_str_n((const char *) cert, cert == NULL ? 0 : cert_len);
  opts.key = mg_str_n((const char *) key, key == NULL ? 0 : key_len);
  opts.name = mg_str_n((const char *) name, name == NULL ? 0 : name_len);
  opts.skip_verification = skip_verification != 0;
  mg_tls_init(c, &opts);
}

// --- Logging ---

// mg_log_set() macro equivalent.
void mgjl_set_log_level(int level) { mg_log_level = level; }

// --- ABI introspection ---

// Sizes of the read-only struct mirrors Mongoose.jl keeps, for a startup sanity check.
size_t mgjl_sizeof_str(void) { return sizeof(struct mg_str); }
size_t mgjl_sizeof_http_header(void) { return sizeof(struct mg_http_header); }
size_t mgjl_sizeof_http_message(void) {
  return sizeof(struct mg_http_message);
}
size_t mgjl_sizeof_ws_message(void) { return sizeof(struct mg_ws_message); }

// MG_VERSION of the linked library, e.g. "7.23".
const char *mgjl_version(void) { return MG_VERSION; }
