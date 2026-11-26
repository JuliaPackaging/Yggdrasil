# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Hwloc"
version = v"2.16.0"

# Collection of sources required to build hwloc
sources = [
    ArchiveSource("https://download.open-mpi.org/release/hwloc/v$(version.major).$(version.minor)/hwloc-$(version).tar.bz2",
                  "ad05eb466b915a4f0e0228173d7e09974ac38760c38d5b6f060254c050fca12d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hwloc-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install

# hwloc's Makefile installs README/NEWS/COPYING directly into ${prefix} on Windows;
# move them to a proper location
if [ -f ${prefix}/README.txt ]; then
    mkdir -p ${prefix}/share/doc/hwloc
    mv -v ${prefix}/README.txt ${prefix}/NEWS.txt ${prefix}/COPYING.txt ${prefix}/share/doc/hwloc/
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libhwloc", :libhwloc),
    ExecutableProduct("lstopo-no-graphics", :lstopo_no_graphics)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("XML2_jll"; compat="~2.15.3"),
    Dependency("Xorg_libpciaccess_jll"; platforms=filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
