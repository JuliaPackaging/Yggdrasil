#include <string.h>
#include <assert.h>
#include <stdlib.h>
#include <unistd.h>

#include <poll.h>
#include <sys/socket.h>
#include <sys/un.h>

// XXX: This is very bad style for a general server, but here
// we know it will be used only for this limited purpose - do not use it
// elsewhere.

int main(int argc, char *argv[]) {
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    assert(fd != -1);

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, "/meta/bb_service", sizeof(addr.sun_path)-1);
    int err = connect(fd, (struct sockaddr *)&addr, sizeof(addr));
    if (err != 0) {
        char error[] = "Failed to connect to BB service\n";
        write(2, error, sizeof(error));
        exit(1);
    }
    assert(err == 0);

    // Send our command line to the server
    for (int i = 0; i < argc; ++i) {
        char *val = argv[i];
        if (i == 0) {
            val = strrchr(val, '/');
            val = val ? val + 1 : argv[0];
        }
        write(fd, val, strlen(val));
        if (i != argc - 1)
            write(fd, " ", 1);
    }
    write(fd, "\n", 1);
    // Don't do this here: https://github.com/JuliaLang/julia/issues/35442
    // shutdown(fd, SHUT_WR);

    // Relay any respose
    char buf[4096];
    while (1) {
        size_t nread = read(fd, buf, sizeof(buf));
        if (nread == 0)
            break;
        write(1, buf, nread);
    }
    return 0;
}
