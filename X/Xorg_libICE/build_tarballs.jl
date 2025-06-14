# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libICE"
version = v"1.1.2"

# Collection of sources required to build libICE
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libICE-$(version).tar.xz",
                  "974e4ed414225eb3c716985df9709f4da8d22a67a2890066bc6dfc89ad298625"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libICE-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->Sys.isapple(p) || Sys.iswindows(p))

products = [
    LibraryProduct("libICE", :libICE),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("Xorg_xtrans_jll"),
    BuildDependency("Xorg_util_macros_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
