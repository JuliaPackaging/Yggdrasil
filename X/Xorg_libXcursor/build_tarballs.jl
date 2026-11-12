# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXcursor"
version = v"1.2.3"
# We bumped the version number to build for riscv64
ygg_version = v"1.2.4"

# Collection of sources required to build libXcursor
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXcursor-$(version).tar.gz",
                  "74e72da27e61cc2cfd2e267c14f500ea47775850048ee0b00362a55c9b60ee9b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXcursor-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libXcursor", :libXcursor),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Xorg_libXfixes_jll"),
    Dependency("Xorg_libXrender_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.6")
