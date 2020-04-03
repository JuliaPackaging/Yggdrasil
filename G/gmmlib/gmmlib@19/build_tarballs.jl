# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "gmmlib"
version = v"19.4.1"

# Collection of sources required to build this package
sources = [
    GitSource("https://github.com/intel/gmmlib.git",
              "ebfcfd565031dbd7b45089d9054cd44a501f14a9"),
]

# Bash recipe for building across all platforms
script = raw"""
cd gmmlib
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
