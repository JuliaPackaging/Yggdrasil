# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Xorg_libXpm"
version = v"3.5.17"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXpm-$(version).tar.xz",
                  "64b31f81019e7d388c822b0b28af8d51c4622b83f1f0cb6fa3fc95e271226e43"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXpm-*
# We need a native xgettext
apk add gettext
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-static=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libXpm", :libXpm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_util_macros_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Xorg_libX11_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
