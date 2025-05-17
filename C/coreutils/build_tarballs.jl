# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "coreutils"
version = v"9.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/coreutils/coreutils-$(version.major).$(version.minor).tar.xz",
                  "e8bb26ad0293f9b5a1fc43fb42ba970e312c66ce92c1b0b16713d7500db251bf")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/coreutils*

# Fix `configure: error: you should not run configure as root (set FORCE_UNSAFE_CONFIGURE=1 in environment to bypass this check)`
if [[ ${target} == x86_64-linux-musl* ]]; then
    export FORCE_UNSAFE_CONFIGURE=1
fi

args=()

# Fix ```
# configure: error: could not enable timestamps after mid-January 2038.
# This package recommends support for these later
# timestamps. However, to proceed with signed 32-bit
# time_t even though it will fail then, configure with
# '--disable-year2038'.
# ```
if [[ ${nbits} == 32 ]]; then
    args+=(--disable-year2038)
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} ${args[@]}
make -j${nproc}
make install

if [[ "${dlext}" != "so" ]]; then
    # Rename shared libraries on Darwin
    mv ${prefix}/libexec/coreutils/libstdbuf.so ${prefix}/libexec/coreutils/libstdbuf.${dlext}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

# The coreutils `configure` stage cannot determine how to get file
# system stats, possily because it calls `AC_RUN` which doesn't work
# when cross-compiling. This fails outright for Windows. For Apple,
# everything works except that the `df` executable is not built.
platforms = supported_platforms(; exclude=p->Sys.iswindows(p) || Sys.isapple(p))

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
