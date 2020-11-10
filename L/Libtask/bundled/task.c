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
#if JULIA_VERSION_MAJOR == 1 && JULIA_VERSION_MINOR >= 1
    if (!t->copy_stack) {
        jl_ptls_t ptls = jl_get_ptls_states();
        t->copy_stack = 1;
        t->bufsz = 0;
        memcpy(&t->ctx, &ptls->base_ctx, sizeof(t->ctx));
    }
#endif
    return t;
}

jl_task_t *jl_clone_task(jl_task_t *t)
{
    jl_ptls_t ptls = jl_get_ptls_states();
    jl_task_t *newt = (jl_task_t*)jl_gc_allocobj(sizeof(jl_task_t)); //  More efficient
    //jl_task_t *newt = (jl_task_t*)jl_new_task(t->start, t->ssize); //  Less efficient
    memset(newt, 0, sizeof(jl_task_t));
    jl_set_typeof(newt, jl_task_type);
    newt->stkbuf = NULL;
    newt->gcstack = NULL;
    JL_GC_PUSH1(&newt);

    newt->state = t->state;
    newt->start = t->start;
    newt->tls = jl_nothing;
    newt->logstate = ptls->current_task->logstate;
    newt->result = jl_nothing;
    newt->donenotify = jl_nothing;
    newt->exception = jl_nothing;
    newt->backtrace = jl_nothing;
    newt->eh = t->eh;
    newt->gcstack = t->gcstack;
    newt->tid = t->tid;          // TODO: need testing
    newt->started = t->started;  // TODO: need testing


#if JULIA_VERSION_MAJOR == 1 && JULIA_VERSION_MINOR >= 1
    newt->copy_stack = t->copy_stack;
    memcpy((void*)newt->ctx.uc_mcontext, (void*)t->ctx.uc_mcontext, sizeof(jl_jmp_buf));
#if JULIA_VERSION_MINOR >= 2
    newt->queue = t->queue;
    newt->sticky = t->sticky;
#endif
#else
    newt->parent = ptls->current_task;
    newt->current_module = t->current_module;
    newt->ssize = t->ssize;  // size of saved piece
    memcpy((void*)newt->ctx, (void*)t->ctx, sizeof(jl_jmp_buf));
#endif

    if (t->stkbuf) {
#if !(JULIA_VERSION_MAJOR == 1 && JULIA_VERSION_MINOR >= 1)
        newt->ssize = t->ssize;  // size of saved piece
#endif
        // newt->stkbuf = allocb(t->bufsz);
        // newt->bufsz = t->bufsz;
        // memcpy(newt->stkbuf, t->stkbuf, t->bufsz);
        // workaround, newt and t will get new stkbuf when savestack is called.
        t->bufsz    = 0;
        newt->bufsz = 0;
        newt->stkbuf = t->stkbuf;
    } else {
#if !(JULIA_VERSION_MAJOR == 1 && JULIA_VERSION_MINOR >= 1)
        newt->ssize = 0;
#endif
        newt->bufsz = 0;
        newt->stkbuf = NULL;
    }

    JL_GC_POP();
    jl_gc_wb_back(newt);

    return newt;
}
