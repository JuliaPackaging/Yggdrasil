# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Fmt"
version = v"9.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/fmtlib/fmt.git", "a33701196adfad74917046096bf5a2aa0ab0bb50")
]

# Bash recipe for building across all platforms
script = raw"""

CC=gcc
CXX=g++

gcc -v

cd $WORKSPACE/srcdir/fmt
mkdir build
cd build

cmake \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=True \
-DCMAKE_INSTALL_PREFIX=${prefix} \
..
make
make install

install_license ../LICENSE.rst
"""

platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macOs"),
    Platform("aarch64", "macOs"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows")
]

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfmt", :libfmt),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
