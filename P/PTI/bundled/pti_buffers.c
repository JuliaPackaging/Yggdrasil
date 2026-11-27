// Buffer callbacks for PTI's view API that do not call back into the host language.
//
// PTI requests buffers from whatever thread records an event, and returns them from its
// own consumer thread, also while the process exits. Runtimes that cannot safely run code
// on such threads (e.g. Julia) pass `pti_buffers_request` and `pti_buffers_complete` to
// `ptiViewSetCallbacks`, and after `ptiFlushAllViews` take the completed buffers with
// `pti_buffers_pop`, releasing each one with `free`.

#include <stdint.h>
#include <stdlib.h>
#include <pthread.h>

#define BUFFER_SIZE (1 << 20)

typedef struct node {
    struct node *next;
    unsigned char *buf;
    size_t used;
} node;

static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
static node *head = NULL, *tail = NULL;
static uint64_t lost = 0;

void pti_buffers_request(unsigned char **buf, size_t *size) {
    *buf = malloc(BUFFER_SIZE);
    *size = *buf ? BUFFER_SIZE : 0;
    if (!*buf) {
        pthread_mutex_lock(&lock);
        lost++;
        pthread_mutex_unlock(&lock);
    }
}

void pti_buffers_complete(unsigned char *buf, size_t size, size_t used) {
    if (!buf)
        return;
    if (!used) {
        free(buf);
        return;
    }
    node *n = malloc(sizeof(node));
    pthread_mutex_lock(&lock);
    if (n) {
        n->next = NULL;
        n->buf = buf;
        n->used = used;
        if (tail)
            tail->next = n;
        else
            head = n;
        tail = n;
    } else {
        lost++;
    }
    pthread_mutex_unlock(&lock);
    if (!n)
        free(buf);
}

// Take the oldest completed buffer, returning 0 if there is none.
int pti_buffers_pop(unsigned char **buf, size_t *used) {
    pthread_mutex_lock(&lock);
    node *n = head;
    if (n) {
        head = n->next;
        if (!head)
            tail = NULL;
    }
    pthread_mutex_unlock(&lock);
    if (!n)
        return 0;
    *buf = n->buf;
    *used = n->used;
    free(n);
    return 1;
}

// Number of buffers whose records were lost because memory could not be allocated.
uint64_t pti_buffers_lost(void) {
    pthread_mutex_lock(&lock);
    uint64_t n = lost;
    pthread_mutex_unlock(&lock);
    return n;
}
