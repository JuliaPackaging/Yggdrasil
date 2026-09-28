#include "mongoose.h"

void *mg_conn_get_fn_data(struct mg_connection *c) {
  return c->fn_data;
}
