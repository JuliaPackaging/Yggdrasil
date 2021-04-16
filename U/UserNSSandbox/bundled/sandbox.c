/* Copyright (c) 2017 Julia Computing Inc */
#define _GNU_SOURCE

/*
  sandbox.c - Sandbox execution platform

This file serves as the entrypoint into our sandboxed/virtualized execution environment for
BinaryBuilder.jl; it has two execution modes:

  1) Unprivileged container mode.
  2) Privileged container mode.

The two modes do similar things, but in different orders and with different privileges. Eventually,
all modes seek the same result; to run a user program with the base root fs and any other shards
requested by the user within the BinaryBuilder.jl execution environment:

* Unprivileged container mode is the "normal" mode of execution; it attempts to use the native
kernel namespace abilities to setup its environment without ever needing to be `root`. It does this
by creating a user namespace, then using its root privileges within the namespace to mount the
necesary shards, `chroot`, etc... within the right places in the new mount namespace created within
the container.

* Privileged container mode is what happens when `sandbox` is invoked with EUID == 0.  In this
mode, the mounts and chroots and whatnot are performed _before_ creating a new user namespace.
This is used as a workaround for kernels that do not have the capabilities for creating mounts
within user namespaces.  Arch Linux is a great example of this.

To test this executable, compile it with:

    gcc -O2 -static -static-libgcc -std=c99 -o /tmp/sandbox ./sandbox.c

Then run it, mounting in a rootfs with a workspace and no other read-only maps:

    mkdir -p /tmp/workspace
    /tmp/sandbox --verbose --rootfs $rootfs_dir --workspace /tmp/workspace:/workspace --cd /workspace /bin/bash
*/


/* Seperate because the headers below don't have all dependencies properly
   declared */
#include <sys/socket.h>

#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/capability.h>
#include <linux/socket.h>
#include <linux/if.h>
#include <linux/in.h>
#include <linux/netlink.h>
#include <linux/route.h>
#include <linux/rtnetlink.h>
#include <linux/sockios.h>
#include <linux/veth.h>
#include <sched.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/ioctl.h>
#include <sys/prctl.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <dirent.h>
#include <libgen.h>
#include <sys/stat.h>
#include <sys/reboot.h>
#include <linux/reboot.h>
#include <linux/limits.h>
#include <getopt.h>
#include <byteswap.h>

/**** Global Variables ***/
#define TRUE 1
#define FALSE 0

// sandbox_root is the location of the rootfs on disk.  This is required.
char *sandbox_root = NULL;

// new_cd is where we will cd to once we start running.
char *new_cd = NULL;

// persist_dir is where we will store overlayfs data.
// Specifying this will allow subsequent invocations to persist temporary state.
char * persist_dir = NULL;

// verbose sets whether we're in verbose mode.
unsigned char verbose = 0;

// Linked list of volume mappings
struct map_list {
    char *map_path;
    char *outside_path;
    struct map_list *prev;
};
struct map_list *maps;
struct map_list *workspaces;

// This keeps track of our execution mode
enum {
  UNPRIVILEGED_CONTAINER_MODE,
  PRIVILEGED_CONTAINER_MODE,
};
static int execution_mode;

/**** General Utilities ***/

/* Like assert, but don't go away with optimizations */
static void _check(int ok, int line) {
  if (!ok) {
    fprintf(stderr, "At line %d, ABORTED (%d: %s)!\n", line, errno, strerror(errno));
    fflush(stdout);
    fflush(stderr);
    _exit(1);
  }
}
#define check(ok) _check(ok, __LINE__)

/* Opens /proc/%pid/%file */
static int open_proc_file(pid_t pid, const char *file, int mode) {
  char path[PATH_MAX];
  int n = snprintf(path, sizeof(path), "/proc/%d/%s", pid, file);
  check(n >= 0 && n < sizeof(path));
  int fd = open(path, mode);
  check(fd != -1);
  return fd;
}

/* `touch` a file; create it if it doesn't already exist. */
static void touch(const char * path) {
  int fd = open(path, O_RDONLY | O_CREAT, S_IRUSR | S_IRGRP | S_IROTH);
  // Ignore EISDIR as sometimes we try to `touch()` a directory
  if (fd == -1 && errno != EISDIR) {
    check(fd != -1);
  }
  close(fd);
}

/* Make all directories up to the given directory name. */
static void mkpath(const char * dir) {
  // If this directory already exists, back out.
  DIR * dir_obj = opendir(dir);
  if( dir_obj ) {
    closedir(dir_obj);
    return;
  }
  // Otherwise, first make sure our parent exists.  Note that dirname()
  // clobbers its input, so we copy to a temporary variable first. >:|
  char dir_dirname[PATH_MAX];
  strncpy(dir_dirname, dir, PATH_MAX);
  mkpath(dirname(&dir_dirname[0]));

  // then create our directory
  int result = mkdir(dir, 0777);
  check((0 == result) || (errno == EEXIST));
}

/**** User namespaces *****
 *
 * For a general overview on user namespaces, see the corresponding manual page
 * user_namespaces(7). In general, user namespaces allow unprivileged users to
 * run privileged executables, by rewriting uids inside the namespaces (and
 * in particular, a user can be root inside the namespace, but not outside),
 * with the kernel still enforcing access protection as if the user was
 * unprivilged (to all files and resources not created exclusively within the
 * namespace). Absent kernel bugs, this provides relatively strong protections
 * against misconfiguration (because no true privilege is ever bestowed upon
 * the sandbox). It should be noted however, that there were such kernel bugs
 * as recently as Feb 2016.  These were sneaky privilege escalation bugs,
 * rather unimportant to the use case of BinaryBuilder, but a recent and fully
 * patched kernel should be considered essential for any security-sensitive
 * work done on top of this infrastructure).
 */
static void configure_user_namespace(uid_t uid, gid_t gid, pid_t pid) {
  int nbytes = 0;

  if (verbose) {
    fprintf(stderr, "--> Mapping %d:%d to root:root within container namespace\n", uid, gid);
  }

  // Setup uid map
  int uidmap_fd = open_proc_file(pid, "uid_map", O_WRONLY);
  check(uidmap_fd != -1);
  char uidmap[100];
  nbytes = snprintf(uidmap, sizeof(uidmap), "0\t%d\t1\n", uid);
  check(nbytes > 0 && nbytes <= sizeof(uidmap));
  check(write(uidmap_fd, uidmap, nbytes) == nbytes);
  close(uidmap_fd);

  // Deny setgroups
  int setgroups_fd = open_proc_file(pid, "setgroups", O_WRONLY);
  char deny[] = "deny";
  check(write(setgroups_fd, deny, sizeof(deny)) == sizeof(deny));
  close(setgroups_fd);

  // Setup gid map
  int gidmap_fd = open_proc_file(pid, "gid_map", O_WRONLY);
  check(gidmap_fd != -1);
  char gidmap[100];
  nbytes = snprintf(gidmap, sizeof(gidmap), "0\t%d\t1", gid);
  check(nbytes > 0 && nbytes <= sizeof(gidmap));
  check(write(gidmap_fd, gidmap, nbytes) == nbytes);
}


/*
 * Mount an overlayfs from `src` onto `dest`, anchoring the changes made to the overlayfs
 * within the folders `work_dir`/upper and `work_dir`/work.  Note that the common case of
 * `src` == `dest` signifies that we "shadow" the original source location and will simply
 * discard any changes made to it when the overlayfs disappears.  This is how we protect our
 * rootfs and shards when mounting from a local filesystem, as well as how we convert a
 * read-only rootfs and shards to a read-write system when mounting from squashfs images.
 */
static void mount_overlay(const char * src, const char * dest, const char * bname,
                          const char * work_dir, uid_t uid, gid_t gid) {
  char upper[PATH_MAX], work[PATH_MAX], opts[3*PATH_MAX+28];

  // Construct the location of our upper and work directories
  snprintf(upper, sizeof(upper), "%s/upper/%s", work_dir, bname);
  snprintf(work, sizeof(work), "%s/work/%s", work_dir, bname);

  // If `src` or `dest` is "", we actually want it to be "/", so adapt here because
  // this is the only place in the code base where we actually need the slash at the
  // end of the directory name.
  if (src[0] == '\0') {
    src = "/";
  }
  if (dest[0] == '\0') {
    dest = "/";
  }

  if (verbose) {
    fprintf(stderr, "--> Mounting overlay of %s at %s (modifications in %s, workspace in %s)\n", src, dest, upper, work);
  }

  // Make the upper and work directories
  mkpath(upper);
  mkpath(work);

  // Construct the opts, mount the overlay
  snprintf(opts, sizeof(opts), "lowerdir=%s,upperdir=%s,workdir=%s", src, upper, work);
  check(0 == mount("overlay", dest, "overlay", 0, opts));

  // Chown this directory to the desired UID/GID, so that it doesn't look like it's
  // owned by "nobody" when we're inside the sandbox.
  check(0 == chown(dest, uid, gid));
}

static void mount_procfs(const char * root_dir, uid_t uid, gid_t gid) {
  char path[PATH_MAX];

  // Mount procfs at <root_dir>/proc
  snprintf(path, sizeof(path), "%s/proc", root_dir);
  if (verbose) {
    fprintf(stderr, "--> Mounting procfs at %s\n", path);
  }
  // Attempt to unmount a previous /proc if it exists
  check(0 == mount("proc", path, "proc", 0, ""));

  // Chown this directory to the desired UID/GID, so that it doesn't look like it's
  // owned by "nobody" when we're inside the sandbox.  We allow this to fail, as
  // sometimes we're trying to chown() something we don't own.
  int ignored = chown(path, uid, gid);
}

static void bind_mount(const char *src, const char *dest, char read_only) {
  if (verbose) {
    if (read_only) {
      fprintf(stderr, "--> Bind-mounting %s over %s (read-only)\n", src, dest);
    } else {
      fprintf(stderr, "--> Bind-mounting %s over %s\n", src, dest);
    }
  }
  // We don't expect workspaces to have any submounts in normal operation.
  // However, for runshell(), workspace could be an arbitrary directory,
  // including one with sub-mounts, so allow that situation with MS_REC.
  touch(dest);
  check(0 == mount(src, dest, "", MS_BIND|MS_REC, NULL));

  if (read_only) {
    // remount to read-only, nodev, suid.
    // we only really care about read-only, but we need to make sure to be stricter
    // than our parent mount. if the parent mount is noexec, we're out of luck,
    // since we do need to execute these files. however, we don't really have a need
    // for suid (only one uid) or device files (none in the image), so passing those
    // extra flags is harmless.  If we ever cared in the future, the thing to do
    // would to do would be to read `/proc/self/fdinfo` or the directory, find the
    // `mnt_id` and extract the correct flags from `/proc/self/mountinfo`.
    check(0 == mount(src, dest, "", MS_BIND|MS_REMOUNT|MS_RDONLY|MS_NODEV|MS_NOSUID, NULL));
  }
}

/*
 * We use this method to get /dev in shape.  If we're running as init, we need to
 * mount full-blown devtmpfs at /dev.  If we're just a sandbox, we only bindmount
 * /dev/{tty,null,urandom,pts,ptmx} into our root_dir.
 */
static void mount_dev(const char * root_dir) {
  char path[PATH_MAX];

  // Bindmount /dev/null into our root_dir
  snprintf(path, sizeof(path), "%s/dev/null", root_dir);
  bind_mount("/dev/null", path, FALSE);

  // Bindmount /dev/tty into our root_dir
  snprintf(path, sizeof(path), "%s/dev/tty", root_dir);
  bind_mount("/dev/tty", path, FALSE);

  // If the host has a /dev/urandom, expose that to the sandboxed process as well.
  if (access("/dev/urandom", F_OK) == 0) {
    snprintf(path, sizeof(path), "%s/dev/urandom", root_dir);
    bind_mount("/dev/urandom", path, FALSE);
  }

  // Do the same for /dev/pts and /dev/ptmx
  snprintf(path, sizeof(path), "%s/dev/pts", root_dir);
  mkpath(path);
  check(0 == mount("devpts", path, "devpts", 0, "ptmxmode=0666"));

  snprintf(path, sizeof(path), "%s/dev/pts/ptmx", root_dir);
  char ptmx_dst[PATH_MAX];
  snprintf(ptmx_dst, sizeof(ptmx_dst), "%s/dev/ptmx", root_dir);
  bind_mount(path, ptmx_dst, FALSE);

  // Bindmount /dev/shm, if it exists (it technically may not)
  if (access("/dev/shm", F_OK) == 0) {
    snprintf(path, sizeof(path), "%s/dev/shm", root_dir);
    mkpath(path);
    bind_mount("/dev/shm", path, FALSE);
  }
}

static void mount_maps(const char * dest, struct map_list * workspaces, uint8_t read_only) {
  char path[PATH_MAX];

  struct map_list *current_entry = workspaces;
  while( current_entry != NULL ) {
    char *inside = current_entry->map_path;

    // take the path relative to root_dir
    while (inside[0] == '/') {
      inside = inside + 1;
    }
    snprintf(path, sizeof(path), "%s/%s", dest, inside);

    // retport to the user, signifying a read-write mount as a "workspace".
    if (verbose) {
      if (read_only) {
        fprintf(stderr, "--> mapping %s to %s\n", current_entry->outside_path, path);
      } else {
        fprintf(stderr, "--> workspacing %s to %s\n", current_entry->outside_path, path);
      }
    }
    
    // Ensure there is a directory ready to receive the mount, then bind-mount it.
    mkpath(path);
    bind_mount(current_entry->outside_path, path, read_only);
    current_entry = current_entry->prev;
  }
}

/*
 * Helper function that mounts pretty much everything:
 *   - procfs
 *   - our overlay work directory
 *   - the rootfs
 *   - the shards
 *   - the workspace (if given by the user)
 */
static void mount_the_world(const char * root_dir,
                            struct map_list * shard_maps,
                            struct map_list * workspaces,
                            uid_t uid, gid_t gid,
                            const char * persist_dir) {
  // If `persist_dir` is specified, it represents a host directory that should
  // be used to store our overlayfs work data.  This is where modifications to
  // the rootfs and such will go.  Typically, these should be ephemeral (and if
  // `persist_dir` is `NULL`, it will be mounted in a `tmpfs` so that the
  // modifcations are lost immediately) but if `persist_dir` is given, the
  // mounting will be done with modifications stored in that directory.
  // The caller will be responsible for cleaning up the `work` and `upper`
  // directories wtihin `persist_dir`, but subsequent invocations of `sandbox`
  // with the same `--persist` argument will allow resuming execution inside of
  // a rootfs with the previous modifications intact.
  if (persist_dir == NULL) {
    // We know that `/proc` will always be available on basically any Linux
    // system, so we mount our tmpfs here.  It's also convenient because we
    // will mount an actual `procfs` over this at the end of this function, so
    // the overlayfs work directories are completely hidden from view.
    persist_dir = "/proc";

    // Create tmpfs to store ephemeral changes.  These changes are lost once
    // the `tmpfs` is unmounted, which occurs when all processes within the
    // namespace exit and the mount namespace is destroyed.
    check(0 == mount("tmpfs", "/proc", "tmpfs", 0, "size=1G"));
  }

  if (verbose) {
    fprintf(stderr, "--> Creating overlay workdir at %s\n", persist_dir);
  }

  // The first thing we do is create an overlay mounting `root_dir` over itself.
  // `root_dir` is the path to the already loopback-mounted rootfs image, and we
  // are mounting it as an overlay over itself, so that we can make modifications
  // without altering the actual rootfs image.  When running in privileged mode,
  // we're mounting before cloning, in unprivileged mode, we clone before calling
  // this mehod at all.sta
  mount_overlay(root_dir, root_dir, "rootfs", persist_dir, uid, gid);

  // Mount all of our read-only mounts
  mount_maps(root_dir, shard_maps, TRUE);

  // Mount /proc within the sandbox.
  mount_procfs(root_dir, uid, gid);

  // Mount /dev stuff
  mount_dev(root_dir);

  // Mount all our read-write mounts (workspaces)
  mount_maps(root_dir, workspaces, FALSE);

  // Once we're done with that, put /proc back in its place in the big world.
  // This is not strictly necessary since if all goes well, we're going to
  // `pivot_root()` into the rootfs, but it helps with debugging.
  if (strcmp(persist_dir, "/proc") == 0) {
    mount_procfs("", uid, gid);
  }
}

/*
 * Sets up the chroot jail, then executes the target executable.
 */
static int sandbox_main(const char * root_dir, const char * new_cd, int sandbox_argc, char **sandbox_argv) {
  pid_t pid;
  int status;

  // One of the few places where we need to not use `""`, but instead expand it to `"/"`
  if (root_dir[0] == '\0') {
    root_dir = "/";
  }

  // Use `pivot_root()` to avoid bad interaction between `chroot()` and `clone()`,
  // where we get an EPERM on nested sandboxing.
  check(0 == chdir(root_dir));
  if (syscall(SYS_pivot_root, ".", ".") == 0) {
    check(0 == umount2(".", MNT_DETACH));
    check(0 == chdir("/"));
  } else {
    check(0 == chroot(root_dir));
  }

  // If we've got a directory to change to, do so, possibly creating it if we need to
  if (new_cd) {
    mkpath(new_cd);
    check(0 == chdir(new_cd));
  }

  // When the main pid dies, we exit.
  pid_t main_pid;
  if ((main_pid = fork()) == 0) {
    if (verbose) {
      fprintf(stderr, "About to run `%s` ", sandbox_argv[0]);
      int argc_i;
      for( argc_i=1; argc_i<sandbox_argc; ++argc_i) {
        fprintf(stderr, "`%s` ", sandbox_argv[argc_i]);
      }
      fprintf(stderr, "\n");
    }
    execve(sandbox_argv[0], sandbox_argv, environ);
    fprintf(stderr, "ERROR: Failed to run %s: %d (%s)\n", sandbox_argv[0], errno, strerror(errno));

    // Flush to make sure we've said all we're going to before we _exit()
    fflush(stdout);
    fflush(stderr);
    _exit(1);
  }

  // Let's perform normal init functions, handling signals from orphaned
  // children, etc
  sigset_t waitset;
  sigemptyset(&waitset);
  sigaddset(&waitset, SIGCHLD);
  sigprocmask(SIG_BLOCK, &waitset, NULL);
  for (;;) {
    int sig;
    sigwait(&waitset, &sig);

    pid_t reaped_pid;
    while ((reaped_pid = waitpid(-1, &status, 0)) != -1) {
      if (reaped_pid == main_pid) {
        // If it was the main pid that exited, return as well.
        return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
      }
    }
  }
}

static void print_help() {
  fputs("Usage: sandbox --rootfs <dir> [--cd <dir>] ", stderr);
  fputs("[--map <from>:<to>, --map <from>:<to>, ...] ", stderr);
  fputs("[--workspace <from>:<to>, --workspace <from>:<to>, ...] ", stderr);
  fputs("[--persist <work_dir>] ", stderr);
  fputs("[--entrypoint <exe_path>] ", stderr);
  fputs("[--verbose] [--help] <cmd>\n", stderr);
  fputs("\nExample:\n", stderr);
  fputs("  mkdir -p /tmp/workspace\n", stderr);
  fputs("  /tmp/sandbox --verbose --rootfs $rootfs_path --workspace /tmp/workspace:/workspace --cd /workspace /bin/bash\n", stderr);
}

static void sigint_handler() { _exit(0); }

/*
 * Let's get this party started.
 */
int main(int sandbox_argc, char **sandbox_argv) {
  int status = 0;
  pid_t pgrp = getpgid(0);
  char * entrypoint = NULL;

  // First, determine our execution mode based on pid and euid (allowing for override)
  const char * forced_mode = getenv("FORCE_SANDBOX_MODE");
  if (forced_mode != NULL) {
    if (strcmp(forced_mode, "privileged") == 0) {
      execution_mode = PRIVILEGED_CONTAINER_MODE;
    } else if (strcmp(forced_mode, "unprivileged") == 0) {
      execution_mode = UNPRIVILEGED_CONTAINER_MODE;
    } else {
      fprintf(stderr, "ERROR: Unknown FORCE_SANDBOX_MODE argument \"%s\"\n", forced_mode);
      _exit(1);
    }
  } else {
    if(geteuid() == 0) {
      execution_mode = PRIVILEGED_CONTAINER_MODE;
    } else {
      execution_mode = UNPRIVILEGED_CONTAINER_MODE;
    }

    // Once we're inside the sandbox, we can always use "unprivileged" mode
    // since we've got mad permissions inside; so just always do that.
    setenv("FORCE_SANDBOX_MODE", "unprivileged", 0);
  }

  uid_t uid = getuid();
  gid_t gid = getgid();

  // If we're running inside of `sudo`, we need to grab the UID/GID of the calling user through
  // environment variables, not using `getuid()` or `getgid()`.  :(
  const char * SUDO_UID = getenv("SUDO_UID");
  if (SUDO_UID != NULL && SUDO_UID[0] != '\0') {
    uid = strtol(SUDO_UID, NULL, 10);
  }
  const char * SUDO_GID = getenv("SUDO_GID");
  if (SUDO_GID != NULL && SUDO_GID[0] != '\0') {
    gid = strtol(SUDO_GID, NULL, 10);
  }

  // Hide these from children so that we don't carry the outside UID numbers into
  // nested sandboxen; that would cause problems when we refer to UIDs that don't exist.
  unsetenv("SUDO_UID");
  unsetenv("SUDO_GID");

  // Parse out options
  while(1) {
    static struct option long_options[] = {
      {"help",       no_argument,       NULL, 'h'},
      {"verbose",    no_argument,       NULL, 'v'},
      {"rootfs",     required_argument, NULL, 'r'},
      {"workspace",  required_argument, NULL, 'w'},
      {"entrypoint", required_argument, NULL, 'e'},
      {"persist",    required_argument, NULL, 'p'},
      {"cd",         required_argument, NULL, 'c'},
      {"map",        required_argument, NULL, 'm'},
      {0, 0, 0, 0}
    };

    int opt_idx;
    int c = getopt_long(sandbox_argc, sandbox_argv, "", long_options, &opt_idx);

    // End of options
    if( c == -1 )
      break;

    switch( c ) {
      case '?':
      case 'h':
        print_help();
        return 0;
      case 'v':
        verbose = 1;
        fprintf(stderr, "verbose sandbox enabled (running in ");
        switch (execution_mode) {
          case UNPRIVILEGED_CONTAINER_MODE:
            fprintf(stderr, "un");
          case PRIVILEGED_CONTAINER_MODE:
            fprintf(stderr, "privileged container");
            break;
        }
        fprintf(stderr, " mode)\n");
        break;
      case 'r': {
        sandbox_root = strdup(optarg);
        size_t sandbox_root_len = strlen(sandbox_root);
        if (sandbox_root[sandbox_root_len-1] == '/' ) {
            sandbox_root[sandbox_root_len-1] = '\0';
        }
        if (verbose) {
          fprintf(stderr, "Parsed --rootfs as \"%s\"\n", sandbox_root);
        }
      } break;
      case 'c':
        new_cd = strdup(optarg);
        if (verbose) {
          fprintf(stderr, "Parsed --cd as \"%s\"\n", new_cd);
        }
        break;
      case 'w':
      case 'm': {
        // Find the colon in "from:to"
        char *colon = strchr(optarg, ':');
        check(colon != NULL);

        // Extract "from" and "to"
        char *from = strndup(optarg, (colon - optarg));
        char *to = strdup(colon + 1);
        if ((from[0] != '/') && (strncmp(from, "9p/", 3) != 0)) {
          fprintf(stderr, "ERROR: Outside path \"%s\" must be absolute or 9p!  Ignoring...\n", from);
          break;
        }

        // Construct `map_list` object for this `from:to` pair
        struct map_list *entry = (struct map_list *) malloc(sizeof(struct map_list));
        entry->map_path = to;
        entry->outside_path = from;

        // If this was `--map`, then add it to `maps`, if it was `--workspace` add it to `workspaces`
        if (c == 'm') {
          entry->prev = maps;
          maps = entry;
        } else {
          entry->prev = workspaces;
          workspaces = entry;
        }
        if (verbose) {
          fprintf(stderr, "Parsed --%s as \"%s\" -> \"%s\"\n", c == 'm' ? "map" : "workspace",
                  entry->outside_path, entry->map_path);
        }
      } break;
      case 'p':
        persist_dir = strdup(optarg);
        if (verbose) {
          fprintf(stderr, "Parsed --persist as \"%s\"\n", persist_dir);
        }
        break;
      case 'e':
        entrypoint = strdup(optarg);
        break;
      default:
        fputs("getoptlong defaulted?!\n", stderr);
        return 1;
    }
  }

  // Skip past those arguments
  sandbox_argv += optind;
  sandbox_argc -= optind;

  // If we were given an entrypoint, push that onto the front of `sandbox_argv`
  if (entrypoint != NULL) {
    // Yes, we clobber sandbox_argv[-1] here; but we already know that `optind` >= 2
    // since `entrypoint != NULL`, so this is acceptable.
    sandbox_argv -= 1;
    sandbox_argc += 1;
    sandbox_argv[0] = entrypoint;
  }

  // If we don't have a command, die
  if (sandbox_argc == 0) {
    fputs("No <cmd> given!\n", stderr);
    print_help();
    return 1;
  }

  // If we haven't been given a sandbox root, die
  if (!sandbox_root) {
    fputs("--rootfs is required!\n", stderr);
    print_help();
    return 1;
  }

  // If we're running in one of the container modes, we're going to syscall() ourselves a
  // new, cloned process that is in a container process. We will use a pipe for synchronization.
  // The regular SIGSTOP method does not work because container-inits don't receive STOP or KILL
  // signals from within their own pid namespace.
  int child_block[2], parent_block[2];
  check(0 == pipe(child_block));
  check(0 == pipe(parent_block));
  pid_t pid;

  if (execution_mode == PRIVILEGED_CONTAINER_MODE) {
    // We dissociate ourselves from the typical mount namespace.  This gives us the freedom
    // to start mounting things willy-nilly without mucking up the user's computer.
    check(0 == unshare(CLONE_NEWNS));

    // Even if we unshare, we might need to mark `/` as private, as systemd often subverts
    // the kernel's default value of `MS_PRIVATE` on the root mount.  This doesn't effect
    // the main root mount, because we have unshared, but this prevents our changes to
    // any subtrees of `/` (e.g. everything) from propagating back to the outside `/`.
    check(0 == mount(NULL, "/", NULL, MS_PRIVATE|MS_REC, NULL));

    // Mount the rootfs, shards, and workspace.  We do this here because, on this machine,
    // we may not have permissions to mount overlayfs within user namespaces.
    mount_the_world(sandbox_root, maps, workspaces, uid, gid, persist_dir);
  }

  // We want to request a new PID space, a new mount space, and a new user space
  int clone_flags = CLONE_NEWPID | CLONE_NEWNS | CLONE_NEWUSER | SIGCHLD;
  if ((pid = syscall(SYS_clone, clone_flags, 0, 0, 0, 0)) == 0) {
    // If we're in here, we have become the "child" process, within the container.

    // Get rid of the ends of the synchronization pipe that I'm not going to use
    close(child_block[1]);
    close(parent_block[0]);

    // N.B: Capabilities in the original user namespaces are now dropped
    // The kernel may have decided to reset our dumpability, because of
    // the privilege change. However, the parent needs to access our /proc
    // entries (undumpable processes have /proc/%pid owned by root) in order
    // to configure the sandbox, so reset dumpability.
    prctl(PR_SET_DUMPABLE, 1, 0, 0, 0);

    // Make sure ^C actually kills this process. By default init ignores
    // all signals.
    signal(SIGINT, sigint_handler);

    // Tell the parent we're ready, and wait until it signals that it's done
    // setting up our PID/GID mapping in configure_user_namespace()
    close(parent_block[1]);
    check(0 == read(child_block[0], NULL, 1));

    if (execution_mode == PRIVILEGED_CONTAINER_MODE) {
      // If we are in privileged container mode, let's go ahead and drop back
      // to the original calling user's UID and GID, which has been mapped to
      // zero within this container.
      check(0 == setuid(0));
      check(0 == setgid(0));

      // The /proc mountpoint previously mounted is in the wrong PID namespace;
      // mount a new procfs over it to to get better values:
      mount_procfs(sandbox_root, 0, 0);
    } else if (execution_mode == UNPRIVILEGED_CONTAINER_MODE) {
      // If we're in unprivileged container mode, mount the world now that we
      // have supreme cosmic power.
      mount_the_world(sandbox_root, maps, workspaces, 0, 0, persist_dir);
    }

    // Finally, we begin invocation of the target program.
    return sandbox_main(sandbox_root, new_cd, sandbox_argc, sandbox_argv);
  }

  // If we're out here, we are still the "parent" process.  The Prestige lives on.

  // Check to make sure that the clone actually worked
  check(pid != -1);

  // Get rid of the ends of the synchronization pipe that I'm not going to use.
  close(child_block[0]);
  close(parent_block[1]);

  // Wait until the child is ready to be configured.
  check(0 == read(parent_block[0], NULL, 1));
  if (verbose) {
    fprintf(stderr, "Child Process PID is %d\n", pid);
  }

  // Configure user namespace for the child PID.
  configure_user_namespace(uid, gid, pid);

  // Signal to the child that it can now continue running.
  close(child_block[1]);

  // Wait until the child exits.
  check(pid == waitpid(pid, &status, 0));
  check(WIFEXITED(status));
  if (verbose) {
    fprintf(stderr, "Child Process exited, exit code %d\n", WEXITSTATUS(status));
  }

  // Give back the terminal to the parent
  signal(SIGTTOU, SIG_IGN);
  tcsetpgrp(0, pgrp);

  // Return the error code of the child
  return WEXITSTATUS(status);
}
