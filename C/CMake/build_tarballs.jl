# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CMake"
version = v"3.17.1"

# Collection of sources required to build CMake
sources = [
    ArchiveSource("https://github.com/Kitware/CMake/releases/download/v$(version)/cmake-$(version).tar.gz",
                  "3aa9114485da39cbd9665a0bfe986894a282d5f0882b1dea960a739496620727"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cmake-*/

cmake -DCMAKE_INSTALL_PREFIX=$prefix

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
# CMake is in C++ and it exports the C++ string ABIs, but when compiling it with
# the C++03 string ABI it seems to ignore our request, so let's just build for
# the C++11 string ABI.
platforms = [
    Linux(:i686, libc = :glibc, compiler_abi = CompilerABI(cxxstring_abi = :cxx11)),
    Linux(:x86_64, libc = :glibc, compiler_abi = CompilerABI(cxxstring_abi = :cxx11)),
    Linux(:x86_64, libc = :musl, compiler_abi = CompilerABI(cxxstring_abi = :cxx11)),
]

# platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("cmake", :cmake),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

