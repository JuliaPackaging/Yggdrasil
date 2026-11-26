# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xkbcomp"
version = v"1.5.0"

# Collection of sources required to build xkbcomp
sources = [
    ArchiveSource("https://www.x.org/archive/individual/app/xkbcomp-$(version).tar.xz",
                  "2ac31f26600776db6d9cd79b3fcd272263faebac7eb85fb2f33c7141b8486060"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xkbcomp-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    ExecutableProduct("xkbcomp", :xkbcomp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Xorg_libxkbfile_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
