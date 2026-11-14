/*
 * bb_jobserver: limits how many compiler processes run at once across all the
 * BinaryBuilder builds on a machine.
 *
 * Usage:
 *   bb_jobserver serve <dir> <num_slots>
 *   bb_jobserver session <dir> <num_slots>
 *   bb_jobserver run [--] <command> [args...]
 *
 * `serve` is the jobserver daemon.  It listens on the Unix socket `<dir>/socket`, and
 * only one daemon runs per `<dir>`: it holds an exclusive flock() on
 * `<dir>/daemon.lock`, which also records its pid.  Clients send one-line messages:
 *   "s <n>"      a session, which keeps the daemon alive and asks for a pool of at
 *                least <n> slots.  Answered with "ok".
 *   "w <group>"  a request for a slot.  Once the client has one, the daemon answers
 *                "g" if it watches the client's pid (from SO_PEERCRED) through a
 *                pidfd: the slot is then held until that process exits.  Otherwise it
 *                answers "h", and the slot is held until the connection closes.
 * The pool size is the largest <n> of the connected sessions (<num_slots> while there
 * are none).  A free slot goes to the waiting client whose group was served least
 * recently, and to the oldest request within that group, so concurrent builds (one
 * group each) take turns.  Slots can't leak: the kernel closes the connections of
 * clients that die, and a watched pid's pidfd reports its exit.  The daemon exits once
 * it has had no connections for
 * BB_JOBSERVER_IDLE_TIMEOUT_MS milliseconds (default 10000).
 *
 * `session` makes sure a daemon is running for `<dir>`, starting one in the background
 * if there is none, opens a session with it, prints "ready" and keeps the session open
 * until its stdin reaches EOF.  BinaryBuilder runs one for the duration of each build.
 * If the daemon dies, the session starts a new one.
 *
 * `run` runs a command once it has a slot.  It just execs the command if
 * BB_JOBSERVER_SOCKET is unset, if BB_JOBSERVER_HELD is set (the caller already runs
 * under a slot, like `as` started by `gcc`), or if the daemon can't be reached.
 * Otherwise it asks the daemon at BB_JOBSERVER_SOCKET for a slot as group
 * BB_JOBSERVER_GROUP and then execs the command, so the command keeps run's pid,
 * signals and exit status.  The slot is held until the command exits: the daemon
 * watches its pid, or, if it can't, a small helper process holds the connection open
 * until then.  The command and its children get BB_JOBSERVER_HELD=1.  Killing run's
 * parent while run still waits for a slot kills run too.  A command whose stdin is a
 * pipe that a live writer has put data in runs without a slot once it has waited
 * PIPELINE_ESCAPE_MS, so `cpp x.S | as` can't deadlock against a producer that holds
 * the last slot and is blocked on the full pipe.
 *
 * Setting BB_JOBSERVER_LOG to a file name makes every subcommand log to that file.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <poll.h>
#include <signal.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <sys/file.h>
#include <sys/ioctl.h>
#include <sys/prctl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#ifndef SYS_pidfd_open
#define SYS_pidfd_open 434
#endif
#ifndef SYS_close_range
#define SYS_close_range 436
#endif

#define DEFAULT_IDLE_TIMEOUT_MS 10000
#define SESSION_START_MS        10000
#define SPAWN_RETRY_MS          200
#define PIPELINE_ESCAPE_MS      500
#define PIPELINE_POLL_MS        50
#define MAX_LINE                256

static FILE *log_file;
static const char *log_role = "";

static int64_t now_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

static void sleep_ms(int ms)
{
    struct timespec ts = {ms / 1000, (long)(ms % 1000) * 1000000};
    while (nanosleep(&ts, &ts) != 0 && errno == EINTR)
        ;
}

static void open_log(const char *role)
{
    const char *path = getenv("BB_JOBSERVER_LOG");
    log_role = role;
    if (path && *path) {
        log_file = fopen(path, "ae");
        if (log_file)
            setvbuf(log_file, NULL, _IOLBF, 0);
    }
}

static void logmsg(const char *fmt, ...)
{
    if (!log_file)
        return;
    int saved_errno = errno;
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    va_list ap;
    va_start(ap, fmt);
    fprintf(log_file, "[%lld.%03ld] %s[%d]: ", (long long)ts.tv_sec, ts.tv_nsec / 1000000,
            log_role, (int)getpid());
    vfprintf(log_file, fmt, ap);
    fputc('\n', log_file);
    va_end(ap);
    errno = saved_errno;
}

/* Write all of `msg` to the socket `fd`, without raising SIGPIPE. */
static int send_all(int fd, const char *msg)
{
    size_t len = strlen(msg);
    while (len > 0) {
        ssize_t n = send(fd, msg, len, MSG_NOSIGNAL);
        if (n < 0) {
            if (errno == EINTR)
                continue;
            return -1;
        }
        msg += n;
        len -= (size_t)n;
    }
    return 0;
}

static int write_all(int fd, const char *msg)
{
    size_t len = strlen(msg);
    while (len > 0) {
        ssize_t n = write(fd, msg, len);
        if (n < 0) {
            if (errno == EINTR)
                continue;
            return -1;
        }
        msg += n;
        len -= (size_t)n;
    }
    return 0;
}

static int cmp_int(const void *a, const void *b)
{
    return *(const int *)a - *(const int *)b;
}

static void close_fd_range(int lo, int hi)
{
    if (lo > hi)
        return;
    if (syscall(SYS_close_range, (unsigned)lo, (unsigned)hi, 0) == 0)
        return;
    long max = sysconf(_SC_OPEN_MAX);
    if (max < 0 || max > 65536)
        max = 65536;
    for (long fd = lo; fd <= hi && fd < max; fd++)
        close((int)fd);
}

/* Close every fd from 3 up, except the (at most 4) fds in `keep`; negative entries
 * are ignored. */
static void close_fds_except(const int *keep, int num_keep)
{
    int sorted[4], n = 0;
    for (int i = 0; i < num_keep && n < 4; i++)
        if (keep[i] >= 3)
            sorted[n++] = keep[i];
    qsort(sorted, (size_t)n, sizeof(int), cmp_int);
    int lo = 3;
    for (int i = 0; i < n; i++) {
        close_fd_range(lo, sorted[i] - 1);
        lo = sorted[i] + 1;
    }
    close_fd_range(lo, INT_MAX);
}

static void stdio_to_devnull(void)
{
    int null = open("/dev/null", O_RDWR);
    if (null < 0)
        return;
    for (int fd = 0; fd < 3; fd++)
        if (null != fd)
            dup2(null, fd);
    if (null > 2)
        close(null);
}

/*
 * Fill in `addr` for the socket at `path`.  A path too long for `sun_path` is reached
 * through `/proc/self/fd/<n>/`; `*dirfd` then holds the directory open, and the caller
 * closes it once it is done with the address.
 */
static int socket_address(const char *path, struct sockaddr_un *addr, int *dirfd)
{
    memset(addr, 0, sizeof(*addr));
    addr->sun_family = AF_UNIX;
    *dirfd = -1;
    if (strlen(path) < sizeof(addr->sun_path)) {
        strcpy(addr->sun_path, path);
        return 0;
    }
    const char *slash = strrchr(path, '/');
    char dir[PATH_MAX];
    size_t dir_len = slash ? (size_t)(slash - path) : 0;
    if (!slash || dir_len >= sizeof(dir)) {
        errno = ENAMETOOLONG;
        return -1;
    }
    memcpy(dir, path, dir_len);
    dir[dir_len] = '\0';
    *dirfd = open(dir_len ? dir : "/", O_PATH | O_DIRECTORY | O_CLOEXEC);
    if (*dirfd < 0)
        return -1;
    int len = snprintf(addr->sun_path, sizeof(addr->sun_path), "/proc/self/fd/%d/%s",
                       *dirfd, slash + 1);
    if (len < 0 || (size_t)len >= sizeof(addr->sun_path)) {
        close(*dirfd);
        *dirfd = -1;
        errno = ENAMETOOLONG;
        return -1;
    }
    return 0;
}

static int connect_socket(const char *path)
{
    struct sockaddr_un addr;
    int dirfd;
    if (socket_address(path, &addr, &dirfd) != 0)
        return -1;
    int fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
    if (fd >= 0 && connect(fd, (struct sockaddr *)&addr, sizeof(addr)) != 0) {
        int saved_errno = errno;
        close(fd);
        fd = -1;
        errno = saved_errno;
    }
    if (dirfd >= 0) {
        int saved_errno = errno;
        close(dirfd);
        errno = saved_errno;
    }
    return fd;
}

/* Read one line from `fd` within `timeout` ms and compare it with `expected`. */
static int read_reply(int fd, const char *expected, int timeout)
{
    char buf[MAX_LINE];
    size_t len = 0;
    int64_t deadline = now_ms() + timeout;
    while (len < sizeof(buf)) {
        int64_t left = deadline - now_ms();
        if (left <= 0)
            return -1;
        struct pollfd p = {fd, POLLIN, 0};
        int n = poll(&p, 1, (int)left);
        if (n < 0 && errno == EINTR)
            continue;
        if (n <= 0)
            return -1;
        ssize_t r = read(fd, buf + len, sizeof(buf) - len);
        if (r < 0 && errno == EINTR)
            continue;
        if (r <= 0)
            return -1;
        len += (size_t)r;
        char *nl = memchr(buf, '\n', len);
        if (nl) {
            *nl = '\0';
            return strcmp(buf, expected) == 0 ? 0 : -1;
        }
    }
    return -1;
}

/* ---------------------------------------------------------------------------------- */
/* serve: the daemon                                                                  */
/* ---------------------------------------------------------------------------------- */

enum client_state { NEW, SESSION, WAITING, HOLDING };

struct group {
    char *name;
    uint64_t last_served;
    int num_clients;
};

struct client {
    int fd;      /* -1 once a holder watched through `pidfd` has closed its connection */
    pid_t pid;   /* the peer's pid in our pid namespace, 0 if unknown */
    int pidfd;   /* watches `pid` while it holds a slot, or -1 */
    enum client_state state;
    struct group *group;
    uint64_t seq;
    int session_slots;
    size_t len;
    char buf[MAX_LINE];
};

static struct client **clients;
static size_t num_clients, cap_clients;
static struct group **groups;
static size_t num_groups, cap_groups;
static int default_slots, num_holding, epoll_fd, listen_fd;
static uint64_t serve_tick, request_seq;

static void *grow(void *array, size_t *cap, size_t elem_size)
{
    size_t new_cap = *cap ? 2 * *cap : 16;
    void *p = realloc(array, new_cap * elem_size);
    if (!p) {
        logmsg("out of memory");
        exit(1);
    }
    *cap = new_cap;
    return p;
}

static struct group *group_get(const char *name)
{
    for (size_t i = 0; i < num_groups; i++) {
        if (strcmp(groups[i]->name, name) == 0) {
            groups[i]->num_clients++;
            return groups[i];
        }
    }
    if (num_groups == cap_groups)
        groups = grow(groups, &cap_groups, sizeof(*groups));
    struct group *g = calloc(1, sizeof(*g));
    if (!g || !(g->name = strdup(name))) {
        logmsg("out of memory");
        exit(1);
    }
    g->num_clients = 1;
    groups[num_groups++] = g;
    return g;
}

static void group_put(struct group *g)
{
    if (--g->num_clients > 0)
        return;
    for (size_t i = 0; i < num_groups; i++) {
        if (groups[i] == g) {
            groups[i] = groups[--num_groups];
            break;
        }
    }
    free(g->name);
    free(g);
}

static int pool_size(void)
{
    int size = 0;
    for (size_t i = 0; i < num_clients; i++)
        if (clients[i]->state == SESSION && clients[i]->session_slots > size)
            size = clients[i]->session_slots;
    return size ? size : default_slots;
}

/* epoll data for `c`'s pidfd; the client's socket uses the plain pointer */
static uint64_t pidfd_tag(struct client *c)
{
    return (uint64_t)(uintptr_t)c | 1;
}

static void close_socket(struct client *c)
{
    epoll_ctl(epoll_fd, EPOLL_CTL_DEL, c->fd, NULL);
    close(c->fd);
    c->fd = -1;
}

static void drop_client(struct client *c)
{
    if (c->state == HOLDING) {
        num_holding--;
        logmsg("slot returned by pid %d (%d in use)", (int)c->pid, num_holding);
    }
    if (c->group)
        group_put(c->group);
    if (c->fd >= 0)
        close_socket(c);
    if (c->pidfd >= 0) {
        epoll_ctl(epoll_fd, EPOLL_CTL_DEL, c->pidfd, NULL);
        close(c->pidfd);
    }
    for (size_t i = 0; i < num_clients; i++) {
        if (clients[i] == c) {
            clients[i] = clients[--num_clients];
            break;
        }
    }
    free(c);
}

/*
 * Watch the process at the other end of `c`'s connection through a pidfd, so that its
 * slot lasts exactly as long as that process: the client may then close the connection
 * (as `run` does when it execs its command).  Returns 0 if that isn't possible; the
 * slot then lasts until the connection closes.
 */
static int watch_holder(struct client *c)
{
    if (c->pid <= 0)
        return 0;
    int pidfd = (int)syscall(SYS_pidfd_open, c->pid, 0);
    if (pidfd < 0)
        return 0;
    /* A client that died has already closed its connection, so if the pid we just
     * opened was recycled, the connection shows it. */
    struct pollfd p = {c->fd, POLLRDHUP, 0};
    struct epoll_event ev = {.events = EPOLLIN, .data.u64 = pidfd_tag(c)};
    if (poll(&p, 1, 0) != 0 || epoll_ctl(epoll_fd, EPOLL_CTL_ADD, pidfd, &ev) != 0) {
        close(pidfd);
        return 0;
    }
    c->pidfd = pidfd;
    return 1;
}

/* Hand out free slots: least recently served group first, oldest request first. */
static void schedule(void)
{
    while (num_holding < pool_size()) {
        struct client *best = NULL;
        for (size_t i = 0; i < num_clients; i++) {
            struct client *c = clients[i];
            if (c->state != WAITING)
                continue;
            if (!best || c->group->last_served < best->group->last_served ||
                (c->group->last_served == best->group->last_served && c->seq < best->seq))
                best = c;
        }
        if (!best)
            return;
        best->state = HOLDING;
        best->group->last_served = ++serve_tick;
        num_holding++;
        if (send_all(best->fd, watch_holder(best) ? "g\n" : "h\n") != 0) {
            drop_client(best);
            continue;
        }
        logmsg("slot granted to pid %d in group '%s' (%d of %d in use)", (int)best->pid,
               best->group->name, num_holding, pool_size());
    }
}

static int handle_line(struct client *c, char *line)
{
    if (c->state != NEW)
        return -1;
    if (line[0] == 's' && line[1] == ' ') {
        char *end;
        long n = strtol(line + 2, &end, 10);
        if (end == line + 2 || *end != '\0' || n < 1 || n > INT_MAX)
            return -1;
        c->state = SESSION;
        c->session_slots = (int)n;
        logmsg("session on fd %d for %ld slots", c->fd, n);
        return send_all(c->fd, "ok\n");
    }
    if (line[0] == 'w' && (line[1] == ' ' || line[1] == '\0')) {
        c->state = WAITING;
        c->seq = ++request_seq;
        c->group = group_get(line[1] ? line + 2 : "");
        return 0;
    }
    return -1;
}

static void handle_client(struct client *c)
{
    ssize_t n = read(c->fd, c->buf + c->len, sizeof(c->buf) - c->len);
    if (n < 0 && (errno == EINTR || errno == EAGAIN))
        return;
    if (n == 0 && c->state == HOLDING && c->pidfd >= 0) {
        /* The holder closed its connection; its pidfd says when it is done */
        close_socket(c);
        return;
    }
    if (n <= 0) {
        drop_client(c);
        return;
    }
    c->len += (size_t)n;
    char *nl;
    while ((nl = memchr(c->buf, '\n', c->len)) != NULL) {
        *nl = '\0';
        if (handle_line(c, c->buf) != 0) {
            logmsg("dropping fd %d after message '%s'", c->fd, c->buf);
            drop_client(c);
            return;
        }
        size_t used = (size_t)(nl + 1 - c->buf);
        memmove(c->buf, nl + 1, c->len - used);
        c->len -= used;
    }
    if (c->len == sizeof(c->buf)) {
        logmsg("dropping fd %d after an overlong message", c->fd);
        drop_client(c);
    }
}

/* Accept every pending connection; returns how many there were. */
static int accept_clients(void)
{
    int accepted = 0;
    for (;;) {
        int fd = accept4(listen_fd, NULL, NULL, SOCK_NONBLOCK | SOCK_CLOEXEC);
        if (fd < 0) {
            if (errno == EINTR || errno == ECONNABORTED)
                continue;
            return accepted;
        }
        struct client *c = calloc(1, sizeof(*c));
        if (!c) {
            close(fd);
            continue;
        }
        c->fd = fd;
        c->pidfd = -1;
        c->state = NEW;
        struct ucred cred;
        socklen_t cred_len = sizeof(cred);
        if (getsockopt(fd, SOL_SOCKET, SO_PEERCRED, &cred, &cred_len) == 0)
            c->pid = cred.pid;
        struct epoll_event ev = {.events = EPOLLIN | EPOLLRDHUP, .data.ptr = c};
        if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fd, &ev) != 0) {
            close(fd);
            free(c);
            continue;
        }
        if (num_clients == cap_clients)
            clients = grow(clients, &cap_clients, sizeof(*clients));
        clients[num_clients++] = c;
        accepted++;
    }
}

static int is_client(struct client *c)
{
    for (size_t k = 0; k < num_clients; k++)
        if (clients[k] == c)
            return 1;
    return 0;
}

static int serve(const char *dir, int slots)
{
    default_slots = slots;
    mkdir(dir, 0755);
    if (chdir(dir) != 0) {
        fprintf(stderr, "bb_jobserver: cannot enter %s: %s\n", dir, strerror(errno));
        return 1;
    }
    int lock_fd = open("daemon.lock", O_RDWR | O_CREAT | O_CLOEXEC, 0644);
    if (lock_fd < 0) {
        fprintf(stderr, "bb_jobserver: cannot open %s/daemon.lock: %s\n", dir, strerror(errno));
        return 1;
    }
    if (flock(lock_fd, LOCK_EX | LOCK_NB) != 0) {
        /* Another daemon serves this directory */
        return 0;
    }
    if (ftruncate(lock_fd, 0) == 0)
        dprintf(lock_fd, "%d\n", (int)getpid());

    unlink("socket");
    listen_fd = socket(AF_UNIX, SOCK_STREAM | SOCK_NONBLOCK | SOCK_CLOEXEC, 0);
    struct sockaddr_un addr = {.sun_family = AF_UNIX, .sun_path = "socket"};
    mode_t old_umask = umask(077);
    int bound = listen_fd >= 0 && bind(listen_fd, (struct sockaddr *)&addr, sizeof(addr)) == 0;
    umask(old_umask);
    if (!bound || listen(listen_fd, 128) != 0) {
        fprintf(stderr, "bb_jobserver: cannot listen on %s/socket: %s\n", dir, strerror(errno));
        return 1;
    }
    epoll_fd = epoll_create1(EPOLL_CLOEXEC);
    struct epoll_event lev = {.events = EPOLLIN, .data.ptr = NULL};
    if (epoll_fd < 0 || epoll_ctl(epoll_fd, EPOLL_CTL_ADD, listen_fd, &lev) != 0) {
        fprintf(stderr, "bb_jobserver: epoll: %s\n", strerror(errno));
        return 1;
    }
    int idle_timeout = DEFAULT_IDLE_TIMEOUT_MS;
    const char *idle_env = getenv("BB_JOBSERVER_IDLE_TIMEOUT_MS");
    if (idle_env && *idle_env)
        idle_timeout = atoi(idle_env);
    logmsg("serving %s with %d slots", dir, slots);

    struct epoll_event events[64];
    for (;;) {
        int n = epoll_wait(epoll_fd, events, 64, num_clients ? -1 : idle_timeout);
        if (n < 0) {
            if (errno == EINTR)
                continue;
            logmsg("epoll_wait: %s", strerror(errno));
            return 1;
        }
        if (n == 0) {
            if (num_clients == 0 && accept_clients() == 0)
                break;
            continue;
        }
        for (int i = 0; i < n; i++)
            if (events[i].data.ptr == NULL)
                accept_clients();
        for (int i = 0; i < n; i++) {
            uint64_t data = events[i].data.u64;
            struct client *c = (struct client *)(uintptr_t)(data & ~(uint64_t)1);
            /* An earlier event in this batch may have dropped `c` */
            if (c == NULL || !is_client(c))
                continue;
            if (data & 1)
                drop_client(c);
            else if (c->fd >= 0)
                handle_client(c);
        }
        schedule();
    }
    logmsg("idle, exiting");
    unlink("socket");
    return 0;
}

/* ---------------------------------------------------------------------------------- */
/* session                                                                            */
/* ---------------------------------------------------------------------------------- */

static void spawn_daemon(const char *dir, int slots)
{
    pid_t pid = fork();
    if (pid < 0)
        return;
    if (pid == 0) {
        setsid();
        if (fork() != 0)
            _exit(0);
        /* The daemon outlives this session, so it must not hold on to anything the
         * session's parent handed it (pipes in particular). */
        log_file = NULL;
        stdio_to_devnull();
        close_fds_except(NULL, 0);
        open_log("serve");
        signal(SIGHUP, SIG_IGN);
        signal(SIGINT, SIG_IGN);
        _exit(serve(dir, slots));
    }
    while (waitpid(pid, NULL, 0) < 0 && errno == EINTR)
        ;
}

/* Connect to the daemon for `dir`, starting one if needed, and open a session. */
static int open_session(const char *dir, const char *path, int slots)
{
    char msg[32];
    snprintf(msg, sizeof(msg), "s %d\n", slots);
    int64_t deadline = now_ms() + SESSION_START_MS, next_spawn = 0;
    while (now_ms() < deadline) {
        int fd = connect_socket(path);
        if (fd >= 0) {
            if (send_all(fd, msg) == 0 && read_reply(fd, "ok", 2000) == 0)
                return fd;
            close(fd);
        } else if (now_ms() >= next_spawn) {
            logmsg("no daemon at %s (%s), starting one", path, strerror(errno));
            spawn_daemon(dir, slots);
            next_spawn = now_ms() + SPAWN_RETRY_MS;
            continue;
        }
        sleep_ms(5);
    }
    return -1;
}

static int session(const char *dir, int slots)
{
    char path[PATH_MAX];
    if (snprintf(path, sizeof(path), "%s/socket", dir) >= (int)sizeof(path)) {
        fprintf(stderr, "bb_jobserver: path too long: %s\n", dir);
        return 1;
    }
    mkdir(dir, 0755);
    signal(SIGPIPE, SIG_IGN);
    int announced = 0;
    for (;;) {
        int fd = open_session(dir, path, slots);
        if (fd < 0) {
            fprintf(stderr, "bb_jobserver: cannot start or reach a jobserver daemon in %s\n", dir);
            return 1;
        }
        if (!announced) {
            if (write_all(STDOUT_FILENO, "ready\n") != 0)
                return 1;
            announced = 1;
        }
        struct pollfd p[2] = {{STDIN_FILENO, POLLIN, 0}, {fd, POLLIN, 0}};
        for (;;) {
            if (poll(p, 2, -1) < 0) {
                if (errno == EINTR)
                    continue;
                return 1;
            }
            if (p[0].revents & POLLNVAL)
                return 0;
            if (p[0].revents) {
                char buf[256];
                ssize_t n = read(STDIN_FILENO, buf, sizeof(buf));
                if (n == 0 || (n < 0 && errno != EINTR && errno != EAGAIN))
                    return 0;
            }
            if (p[1].revents) {
                close(fd);
                logmsg("lost the daemon, reconnecting");
                break;
            }
        }
    }
}

/* ---------------------------------------------------------------------------------- */
/* run                                                                                */
/* ---------------------------------------------------------------------------------- */

static void exec_command(char **argv)
{
    execvp(argv[0], argv);
    int e = errno;
    fprintf(stderr, "bb_jobserver: %s: %s\n", argv[0], strerror(e));
    _exit(e == ENOENT ? 127 : 126);
}

enum stdin_state { STDIN_EMPTY, STDIN_DATA, STDIN_CLOSED };

/* Whether data waits in the stdin pipe while some process can still write to it. */
static enum stdin_state stdin_state(void)
{
    struct pollfd p = {STDIN_FILENO, POLLIN, 0};
    if (poll(&p, 1, 0) <= 0)
        return STDIN_EMPTY;
    if (p.revents & (POLLHUP | POLLERR | POLLNVAL))
        return STDIN_CLOSED;
    int pending = 0;
    if ((p.revents & POLLIN) && ioctl(STDIN_FILENO, FIONREAD, &pending) == 0 && pending > 0)
        return STDIN_DATA;
    return STDIN_EMPTY;
}

/* Returns the daemon's answer once it grants a slot ('g' or 'h', see `run()`), or 0 if
 * the command should run without one. */
static int wait_for_grant(int fd)
{
    struct stat st;
    int watch_stdin = fstat(STDIN_FILENO, &st) == 0 && S_ISFIFO(st.st_mode);
    int64_t start = now_ms();
    for (;;) {
        int timeout = -1;
        if (watch_stdin) {
            int64_t waited = now_ms() - start;
            timeout = waited < PIPELINE_ESCAPE_MS ? (int)(PIPELINE_ESCAPE_MS - waited)
                                                  : PIPELINE_POLL_MS;
        }
        struct pollfd p = {fd, POLLIN, 0};
        int n = poll(&p, 1, timeout);
        if (n < 0) {
            if (errno == EINTR)
                continue;
            return 0;
        }
        if (n > 0) {
            char buf[8];
            ssize_t r = read(fd, buf, sizeof(buf));
            if (r < 0 && errno == EINTR)
                continue;
            if (r > 0 && (buf[0] == 'g' || buf[0] == 'h'))
                return buf[0];
            logmsg("lost the daemon while waiting");
            return 0;
        }
        if (watch_stdin && now_ms() - start >= PIPELINE_ESCAPE_MS) {
            switch (stdin_state()) {
            case STDIN_DATA:
                logmsg("data is waiting on stdin, running without a slot");
                return 0;
            case STDIN_CLOSED:
                watch_stdin = 0;
                break;
            case STDIN_EMPTY:
                break;
            }
        }
    }
}

/* The helper process: holds the slot's connection until process `pid` exits. */
static void hold_slot(int fd, int pidfd, pid_t pid)
{
    prctl(PR_SET_NAME, "bb_jobserver-h", 0, 0, 0);
    int ignored[] = {SIGINT, SIGTERM, SIGHUP, SIGQUIT, SIGTSTP, SIGTTIN, SIGTTOU, SIGPIPE};
    for (size_t i = 0; i < sizeof(ignored) / sizeof(ignored[0]); i++)
        signal(ignored[i], SIG_IGN);
    stdio_to_devnull();
    int keep[] = {fd, pidfd, log_file ? fileno(log_file) : -1};
    close_fds_except(keep, 3);

    struct pollfd p[2] = {{fd, POLLIN, 0}, {pidfd, POLLIN, 0}};
    for (;;) {
        int n = poll(p, pidfd >= 0 ? 2 : 1, pidfd >= 0 ? -1 : 100);
        if (n < 0 && errno != EINTR)
            _exit(1);
        /* Either the command exited, or the daemon went away */
        if (n > 0)
            _exit(0);
        if (pidfd < 0 && kill(pid, 0) != 0 && errno == ESRCH)
            _exit(0);
    }
}

/* Move the slot's connection to a helper that isn't a child of the command. */
static void hand_over_slot(int fd)
{
    pid_t self = getpid();
    int pidfd = (int)syscall(SYS_pidfd_open, self, 0);
    pid_t child = fork();
    if (child == 0) {
        if (fork() == 0)
            hold_slot(fd, pidfd, self);
        _exit(0);
    }
    if (child > 0) {
        while (waitpid(child, NULL, 0) < 0 && errno == EINTR)
            ;
    }
    close(fd);
    if (pidfd >= 0)
        close(pidfd);
}

static int run(char **argv)
{
    const char *path = getenv("BB_JOBSERVER_SOCKET");
    if (!path || !*path || getenv("BB_JOBSERVER_HELD"))
        exec_command(argv);
    setenv("BB_JOBSERVER_HELD", "1", 1);

    /* Killing the caller (e.g. the wrapper script) withdraws a request that is still
     * waiting, but leaves a command that is already running alone. */
    pid_t parent = getppid();
    prctl(PR_SET_PDEATHSIG, SIGKILL, 0, 0, 0);
    if (getppid() != parent)
        _exit(128 + SIGKILL);

    int fd = connect_socket(path);
    if (fd < 0) {
        logmsg("cannot reach the daemon at %s (%s), running without a slot", path,
               strerror(errno));
        prctl(PR_SET_PDEATHSIG, 0, 0, 0, 0);
        exec_command(argv);
    }
    const char *group = getenv("BB_JOBSERVER_GROUP");
    char msg[MAX_LINE];
    snprintf(msg, sizeof(msg), "w %.200s", group ? group : "");
    for (char *p = msg; *p; p++)
        if (*p == '\n')
            *p = ' ';
    strcat(msg, "\n");
    /* "g": the daemon watches our pid, which the command keeps, so the connection can
     * close on exec.  "h": the connection must stay open while the command runs. */
    int answer = send_all(fd, msg) == 0 ? wait_for_grant(fd) : 0;
    if (answer == 'h')
        hand_over_slot(fd);
    else
        close(fd);
    prctl(PR_SET_PDEATHSIG, 0, 0, 0, 0);
    exec_command(argv);
    return 127;
}

/* ---------------------------------------------------------------------------------- */

static int usage(void)
{
    fprintf(stderr,
            "usage: bb_jobserver serve <dir> <num_slots>\n"
            "       bb_jobserver session <dir> <num_slots>\n"
            "       bb_jobserver run [--] <command> [args...]\n");
    return 2;
}

int main(int argc, char **argv)
{
    if (argc >= 2 && strcmp(argv[1], "run") == 0) {
        int i = 2;
        if (i < argc && strcmp(argv[i], "--") == 0)
            i++;
        if (i >= argc)
            return usage();
        open_log("run");
        return run(argv + i);
    }
    if (argc == 4 && (strcmp(argv[1], "serve") == 0 || strcmp(argv[1], "session") == 0)) {
        char *end;
        long slots = strtol(argv[3], &end, 10);
        if (end == argv[3] || *end != '\0' || slots < 1 || slots > INT_MAX)
            return usage();
        if (strcmp(argv[1], "serve") == 0) {
            open_log("serve");
            signal(SIGPIPE, SIG_IGN);
            return serve(argv[2], (int)slots);
        }
        open_log("session");
        return session(argv[2], (int)slots);
    }
    return usage();
}
