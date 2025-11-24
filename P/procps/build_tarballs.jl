# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "procps"
version = v"4.0.5"

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
    GitSource("https://gitlab.com/procps-ng/procps.git",
              "f46b2f7929cdfe2913ed0a7f585b09d6adbf994e")
]

dependencies = Dependency[
    Dependency("Ncurses_jll")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd procps/
apk update && apk add gettext-dev
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-pidwait LDFLAGS="-lrt"
make -j${nproc} install
"""

# Depends on qsort_r for which our musl version is too old
platforms = filter!(p -> Sys.islinux(p) && p["libc"] != "musl", supported_platforms())

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("pidof", :pidof),
    ExecutableProduct("watch", :watch),
    ExecutableProduct("pmap", :pmap),
    ExecutableProduct("top", :top),
    ExecutableProduct("ps", :ps),
    LibraryProduct("libproc2", :libproc2),
    ExecutableProduct("free", :free),
    ExecutableProduct("pgrep", :pgrep),
    ExecutableProduct("pkill", :pkill),
    ExecutableProduct("uptime", :uptime),
    ExecutableProduct("hugetop", :hugetop),
    ExecutableProduct("slabtop", :slabtop),
    ExecutableProduct("tload", :tload),
    ExecutableProduct("pwdx", :pwdx),
    ExecutableProduct("w", :w),
    ExecutableProduct("sysctl", :sysctl, "sbin"),
    ExecutableProduct("vmstat", :vmstat),
    ExecutableProduct("kill", :pskill)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
