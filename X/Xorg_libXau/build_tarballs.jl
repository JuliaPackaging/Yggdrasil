# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXau"
version = v"1.0.12"
# We bumped the version number because we built for riscv64
ygg_version = v"1.0.13"

# Collection of sources required to build libXau
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXau-$(version).tar.xz",
                  "74d0e4dfa3d39ad8939e99bda37f5967aba528211076828464d2777d477fc0fb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXau-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->!(Sys.islinux(p) || Sys.isfreebsd(p)))

products = [
    LibraryProduct("libXau", :libXau),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_util_macros_jll"),
    BuildDependency("Xorg_xproto_jll")
]

# Build the tarballs.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.6")
