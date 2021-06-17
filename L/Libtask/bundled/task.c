/*
 task.c
 task copying (aka continuation) for lightweight processes (symmetric coroutines)
 */

#include "julia.h"

// Workaround for JuliaLang/julia#32812
jl_task_t *vanilla_get_current_task(void)
{
    jl_ptls_t ptls = jl_get_ptls_states();
    return (jl_task_t*)ptls->current_task;
}


jl_task_t *jl_enable_stack_copying(jl_task_t *t)
{
    if (!t->copy_stack) {
        jl_ptls_t ptls = jl_get_ptls_states();
        t->copy_stack = 1;
        t->bufsz = 0;
        memcpy(&t->ctx, &ptls->base_ctx, sizeof(t->ctx));
    }
    return t;
}

jl_task_t *jl_clone_task(jl_task_t *t)
{
    jl_ptls_t ptls = jl_get_ptls_states();
    jl_task_t *newt = (jl_task_t*)jl_gc_allocobj(sizeof(jl_task_t)); //  More efficient
    //jl_task_t *newt = (jl_task_t*)jl_new_task(t->start, t->ssize); //  Less efficient
    memset(newt, 0, sizeof(jl_task_t));
    jl_set_typeof(newt, jl_task_type);
    JL_GC_PUSH1(&newt);

#if JULIA_VERSION_MAJOR == 1 && JULIA_VERSION_MINOR < 6
    newt->state = t->state;
    newt->exception = jl_nothing;
    newt->backtrace = jl_nothing;
#else
    // newt->next = jl_nothing;
    newt->_state = t->_state;
    newt->_isexception = t->_isexception;
    newt->prio = t->prio;
    newt->excstack = NULL; // t->excstack;
#endif

    newt->start = t->start;
    newt->tls = jl_nothing;
    newt->logstate = ptls->current_task->logstate;
    newt->result = jl_nothing;
    newt->donenotify = jl_nothing;
    newt->eh = t->eh;
    newt->gcstack = t->gcstack;
    newt->tid = t->tid;          // TODO: need testing
    newt->started = t->started;  // TODO: need testing

    newt->copy_stack = t->copy_stack;
    memcpy((void*)newt->ctx.uc_mcontext, (void*)t->ctx.uc_mcontext, sizeof(jl_jmp_buf));
    newt->queue = t->queue;
    newt->sticky = t->sticky;

    if (t->stkbuf) {
        // newt->stkbuf = allocb(t->bufsz);
        // newt->bufsz = t->bufsz;
        // memcpy(newt->stkbuf, t->stkbuf, t->bufsz);
        // workaround, newt and t will get new stkbuf when savestack is called.
        t->bufsz    = 0;
        newt->bufsz = 0;
        newt->stkbuf = t->stkbuf;
    } else {
        newt->bufsz = 0;
        newt->stkbuf = NULL;
    }

    JL_GC_POP();
    jl_gc_wb_back(newt);

    return newt;
}


jl_task_t *jl_clone_task_opaque(jl_task_t *t, size_t size)
{
    jl_ptls_t ptls = jl_get_ptls_states();
    jl_task_t *newt = (jl_task_t*)jl_gc_allocobj(size);
    memcpy(newt, t, size);

    jl_set_typeof(newt, jl_task_type);
    memcpy((void*)newt->ctx.uc_mcontext, (void*)t->ctx.uc_mcontext, sizeof(jl_jmp_buf));
    return newt;
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
