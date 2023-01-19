# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CMake"
version = v"3.23.3"

# Collection of sources required to build CMake
sources = [
    ArchiveSource("https://github.com/Kitware/CMake/releases/download/v$(version)/cmake-$(version).tar.gz",
                  "06fefaf0ad94989724b56f733093c2623f6f84356e5beb955957f9ce3ee28809"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cmake-*/

cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN

make -j${nproc}
make install
"""

# Build for all supported platforms.
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("cmake", :cmake),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

