# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "coreutils"
version = v"8.32.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/coreutils/coreutils-8.32.tar.xz", "4458d8de7849df44ccab15e16b1548b285224dbba5f08fac070c1c0e0bcc4cfa")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd coreutils-8.32
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl"),
    Platform("x86_64", "freebsd")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("b2sum", :b2sum),
    ExecutableProduct("timeout", :timeout),
    ExecutableProduct("chown", :chown_bin),
    ExecutableProduct("factor", :factor),
    ExecutableProduct("sha512sum", :sha512sum),
    ExecutableProduct("pathchk", :pathchk),
    ExecutableProduct("fmt", :fmt),
    ExecutableProduct("sort", :sort_bin),
    ExecutableProduct("sha1sum", :sha1sum),
    ExecutableProduct("yes", :yes),
    ExecutableProduct("groups", :groups),
    ExecutableProduct("uname", :uname),
    ExecutableProduct("env", :env),
    ExecutableProduct("mv", :mv_bin),
    ExecutableProduct("sync", :sync),
    ExecutableProduct("base64", :base64),
    ExecutableProduct("truncate", :truncate_bin),
    ExecutableProduct("tsort", :tsort),
    ExecutableProduct("numfmt", :numfmt),
    ExecutableProduct("nice", :nice),
    ExecutableProduct("sleep", :sleep_bin),
    ExecutableProduct("stat", :stat_bin),
    ExecutableProduct("link", :link),
    ExecutableProduct("users", :users),
    ExecutableProduct("printenv", :printenv),
    ExecutableProduct("head", :head),
    ExecutableProduct("split", :split_bin),
    ExecutableProduct("sha224sum", :sha224sum),
    ExecutableProduct("shuf", :shuf),
    ExecutableProduct("chroot", :chroot),
    ExecutableProduct("csplit", :csplit),
    ExecutableProduct("ptx", :ptx),
    LibraryProduct("libstdbuf", :libstdbuf, "libexec/coreutils"),
    ExecutableProduct("dir", :dir),
    ExecutableProduct("chmod", :chmod_bin),
    ExecutableProduct("vdir", :vdir),
    ExecutableProduct("test", :test),
    ExecutableProduct("true", :true_bin),
    ExecutableProduct("sha256sum", :sha256sum),
    ExecutableProduct("expr", :expr),
    ExecutableProduct("basename", :basename_bin),
    ExecutableProduct("pwd", :pwd_bin),
    ExecutableProduct("unexpand", :unexpand),
    ExecutableProduct("cp", :cp_bin),
    ExecutableProduct("ln", :ln),
    ExecutableProduct("runcon", :runcon),
    ExecutableProduct("kill", :kill_bin),
    ExecutableProduct("mkfifo", :mkfifo),
    ExecutableProduct("tac", :tac),
    ExecutableProduct("echo", :echo),
    ExecutableProduct("od", :od),
    ExecutableProduct("logname", :logname),
    ExecutableProduct("rm", :rm_bin),
    ExecutableProduct("pinky", :pinky),
    ExecutableProduct("pr", :pr),
    ExecutableProduct("chcon", :chcon),
    ExecutableProduct("tty", :tty),
    ExecutableProduct("touch", :touch_bin),
    ExecutableProduct("df", :df),
    ExecutableProduct("comm", :comm),
    ExecutableProduct("nohup", :nohup),
    ExecutableProduct("date", :date),
    ExecutableProduct("seq", :seq),
    ExecutableProduct("hostid", :hostid),
    ExecutableProduct("sum", :sum_bin),
    ExecutableProduct("cut", :cut),
    ExecutableProduct("readlink", :readlink_bin),
    ExecutableProduct("realpath", :realpath_bin),
    ExecutableProduct("md5sum", :md5sum),
    ExecutableProduct("install", :install),
    ExecutableProduct("mkdir", :mkdir_bin),
    ExecutableProduct("cksum", :cksum),
    ExecutableProduct("tail", :tail_bin),
    ExecutableProduct("rmdir", :rmdir),
    ExecutableProduct("unlink", :unlink_bin),
    ExecutableProduct("whoami", :whoami),
    ExecutableProduct("false", :false_bin),
    ExecutableProduct("[", :left_bracket),
    ExecutableProduct("mknod", :mknod),
    ExecutableProduct("fold", :fold),
    ExecutableProduct("stty", :stty),
    ExecutableProduct("tr", :tr),
    ExecutableProduct("cat", :cat_bin),
    ExecutableProduct("chgrp", :chgrp),
    ExecutableProduct("ls", :ls),
    ExecutableProduct("shred", :shred),
    ExecutableProduct("who", :who),
    ExecutableProduct("tee", :tee),
    ExecutableProduct("wc", :wc),
    ExecutableProduct("base32", :base32),
    ExecutableProduct("printf", :printf),
    ExecutableProduct("join", :join_bin),
    ExecutableProduct("id", :id),
    ExecutableProduct("mktemp", :mktemp_bin),
    ExecutableProduct("uptime", :uptime),
    ExecutableProduct("stdbuf", :stdbuf),
    ExecutableProduct("uniq", :uniq),
    ExecutableProduct("dd", :dd),
    ExecutableProduct("nl", :nl),
    ExecutableProduct("dircolors", :dircolors),
    ExecutableProduct("basenc", :basenc),
    ExecutableProduct("du", :du),
    ExecutableProduct("sha384sum", :sha384sum),
    ExecutableProduct("nproc", :nproc),
    ExecutableProduct("dirname", :dirname_bin),
    ExecutableProduct("expand", :expand),
    ExecutableProduct("paste", :paste)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
