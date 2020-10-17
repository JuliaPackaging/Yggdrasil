# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "diffutils"
version = v"3.7.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://ftp.gnu.org/gnu/diffutils/diffutils-3.7.tar.xz",
        "b3a7a6221c3dc916085f0d205abf6b8e1ba443d4dd965118da364a1dc1cb3a26",
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/diffutils-*/
if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ../patches/win_signal_handling.patch
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
# skip gnulib-tests on mingw
if [[ "${target}" == *-mingw* ]]; then
    make -j${nproc} SUBDIRS="lib src tests doc man po"
    make install SUBDIRS="lib src tests doc man po"
else
    make -j${nproc}
    make install
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("cmp", :_cmp)
    ExecutableProduct("diff", :_diff)
    ExecutableProduct("diff3", :diff3)
    ExecutableProduct("sdiff", :sdiff)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
