# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libxshmfence"
version = v"1.3.3"

# Collection of sources required to build libxshmfence
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libxshmfence-$(version).tar.xz",
                  "d4a4df096aba96fea02c029ee3a44e11a47eb7f7213c1a729be83e85ec3fde10"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxshmfence-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no --enable-static=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libxshmfence", :libxshmfence),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_util_macros_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
