/*
 task.c
 task copying (aka continuation) for lightweight processes (symmetric coroutines)
 */

#include "julia.h"

// Workaround for JuliaLang/julia#32812
jl_task_t *vanilla_get_current_task(void)
{
#if JULIA_VERSION_MAJOR == 1 && JULIA_VERSION_MINOR <= 6
    jl_ptls_t ptls = jl_get_ptls_states();
    return (jl_task_t*)ptls->current_task;
#else
    jl_task_t *ct = jl_current_task;
    return ct;
#endif
}

jl_task_t *jl_clone_task_opaque(jl_task_t *t, size_t size)
{
#if JULIA_VERSION_MAJOR == 1 && JULIA_VERSION_MINOR > 6
    jl_task_t *ct = jl_current_task;
    t->ptls = ct->ptls;
    if(t->tid != ct->tid) {
        // maybe give a warning here.
    }
#endif
    jl_task_t *newt = (jl_task_t*)jl_gc_allocobj(size);
    memcpy(newt, t, size);

    jl_set_typeof(newt, jl_task_type);
    return newt;
}

void *jl_reset_task_ctx(jl_task_t *t, size_t ctx_offset, size_t ctx_size, size_t boffset)
{

#if JULIA_VERSION_MAJOR == 1 && JULIA_VERSION_MINOR <= 6
    jl_ptls_t ptls = jl_get_ptls_states();
    int8_t *b = (int8_t*)ptls;
    b += boffset;
#else
    jl_task_t *ct = jl_current_task;
    int8_t *b = (int8_t*)(&ct->ptls->base_ctx);
#endif

    int8_t *p = (int8_t*)t;
    p += ctx_offset;

    memcpy(p, b, ctx_size);
    return NULL;
}

void jl_memcpy(void *dest, void *src, size_t size) {
    memcpy(dest, src, size);
}

void jl_memset(void *t, size_t offset0, size_t offset1, int val) {
    int8_t *dest = (int8_t*)t;
    dest += offset0;
    memset(dest, val, offset1 - offset0);
}

// setter
void jl_setfield_null(void *t, size_t offset) {
    int8_t *p = (int8_t*)t;
    p += offset;
    void **f = (void**)p;
    *f = NULL;
}

void jl_setfield_nothing(void *t, size_t offset) {
    int8_t *p = (int8_t*)t;
    p += offset;
    jl_value_t **f = (jl_value_t**)p;
    *f = jl_nothing;
}

void jl_setfield_ptr(void *t, size_t offset, void *ptr) {
    int8_t *p = (int8_t*)t;
    p += offset;
    void **f = (void**)p;
    *f = ptr;
}

#define setter(type)                                               \
    void jl_setfield_##type(void *t, size_t offset, type v) { \
        int8_t *p = (int8_t*)t;                                    \
        p += offset;                                               \
        type *f = (type*)p;                                        \
        *f = v;                                                    \
    }

setter(int8_t);
setter(uint8_t);
setter(int16_t);
setter(uint16_t);
setter(int32_t);
setter(uint32_t);
setter(int64_t);
setter(uint64_t);
setter(size_t);


// getter

void* jl_getfield_ptr(void *t, size_t offset) {
    int8_t *p = (int8_t*)t;
    p += offset;
    void **f = (void**)p;
    return *f;
}

#define getter(type) \
    type jl_getfield_##type(void *t, size_t offset) { \
        int8_t *p = (int8_t*)t;                         \
        p += offset;                                    \
        type *f = (type*)p;                             \
        return *f;                                      \
    }

getter(int8_t);
getter(uint8_t);
getter(int16_t);
getter(uint16_t);
getter(int32_t);
getter(uint32_t);
getter(int64_t);
getter(uint64_t);
getter(size_t);
