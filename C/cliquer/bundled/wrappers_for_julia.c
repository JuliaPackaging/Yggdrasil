// gcc -Wall -O3 -fomit-frame-pointer -funroll-loops -shared -fPIC -o cliquer.so cliquer.c graph.c reorder.c wrappers_for_julia.c

#include "cliquer.h"
#include "graph.h"
#include "set.h"

void wrap_graph_add_edge(graph_t *g, int i, int j) {
    GRAPH_ADD_EDGE(g, i, j);
}

void wrap_set_weight(graph_t *g, int i, int w) {
    g->weights[i] = w;
}

int wrap_set_contains(set_t s, int i) {
    return SET_CONTAINS(s, i) ? 1 : 0;
}

int wrap_set_size(set_t s) {
    return set_size(s);
}

int wrap_set_max_size(set_t s) {
    return SET_MAX_SIZE(s);
}

void wrap_set_free(set_t s) {
    set_free(s);
}

void wrap_set_print(set_t s) {
    set_print(s);
}

clique_options *wrap_create_opts() {
    clique_options *out = malloc(sizeof(clique_options));
    *out = *cliquer_default_options;
    return out;
}

void wrap_free_opts(clique_options *opts) {
    free(opts);
}

void wrap_set_time_func(
    clique_options *opts,
    boolean (*time_function)(int,int,int,int,double,double, clique_options *))
{
    opts->time_function = time_function;
}

void wrap_set_user_func(
    clique_options *opts,
    boolean (*user_function)(set_t,graph_t *,clique_options *))
{
    opts->user_function = user_function;
}

void wrap_set_user_data(
    clique_options *opts,
    void *user_data)
{
    //printf("set %p %p\n", opts, user_data);
    opts->user_data = user_data;
}

void *wrap_get_user_data(clique_options *opts) {
    //printf("get %p %p\n", opts, opts->user_data);
    return opts->user_data;
}
