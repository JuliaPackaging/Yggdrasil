#include "mongoose.h"

void *mg_conn_get_fn_data(struct mg_connection *c) {
  return c == NULL ? NULL : c->fn_data;
}

bool mg_conn_get_remote_addr(const struct mg_connection *c,
                             struct mg_addr *out) {
  if (c == NULL || out == NULL) return false;
  *out = c->rem;
  return true;
}

size_t mg_conn_send_len(const struct mg_connection *c) {
  return c == NULL ? 0 : c->send.len;
}

void mg_conn_error(struct mg_connection *c, const char *msg) {
  if (c != NULL) mg_error(c, "%s", msg == NULL ? "" : msg);
}

void mg_conn_close_after_send(struct mg_connection *c) {
  if (c != NULL) c->is_draining = 1;
}

static size_t mg_print_raw(mg_pfn_t fn, void *arg, va_list *ap) {
  const char *buf = va_arg(*ap, const char *);
  size_t len = va_arg(*ap, size_t);
  struct mg_iobuf *io = (struct mg_iobuf *) arg;
  (void) fn;
  if (buf == NULL || len == 0) return 0;
  return mg_iobuf_add(io, io->len, buf, len);
}

void mg_http_reply_bin(struct mg_connection *c, int code, const char *headers,
                       const void *body, size_t len) {
  mg_http_reply(c, code, headers, "%M", mg_print_raw, (const char *) body, len);
}

size_t mg_sizeof_mgr(void) {
  return sizeof(struct mg_mgr);
}

size_t mg_sizeof_conn(void) {
  return sizeof(struct mg_connection);
}

size_t mg_sizeof_http_message(void) {
  return sizeof(struct mg_http_message);
}

size_t mg_sizeof_tls_opts(void) {
  return sizeof(struct mg_tls_opts);
}
