# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "gmmlib"
version = v"20.1.1"

# Collection of sources required to build gmmlib
sources = [
    ArchiveSource("https://github.com/intel/gmmlib/archive/intel-gmmlib-$(version).tar.gz",
                  "821755657cf51f59d8f3f443c99e3ec9f28d897ff65c219c6a119e4acb5a2ac7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd gmmlib-*
install_license LICENSE.md

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DBUILD_TYPE=Release -DRUN_TEST_SUITE=OFF ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc)
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libigdgmm", :libigdgmm),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"5")
