# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Collection of sources required to build SymEngine
name = "SymEngine"
version = v"0.5.0"
sources = [
    "https://github.com/symengine/symengine/releases/download/v$(version)/symengine-$(version).tar.gz" =>
    "5d02002f00d16a0928d1056e6ecb8f34fd59f3bfd8ed0009a55700334dbae29b",
]

# Bash recipe for building across all platforms

script = raw"""
cd $WORKSPACE/srcdir/symengine-*
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DBUILD_TESTS=no \
      -DBUILD_BENCHMARKS=no \
      -DBUILD_SHARED_LIBS=yes \
      -DWITH_MPC=yes \
      -DWITH_COTIRE=no \
      -DWITH_SYMENGINE_THREAD_SAFE=yes ..
make -j${nproc}
make install
"""

platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libsymengine", "libsymengine-$(version.major).$(version.minor)"], :libsymengine)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "GMP_jll",
    "MPFR_jll",
    "MPC_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
