# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CryptoMiniSat"
version = v"5.8.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/msoos/cryptominisat.git", "e7079937ed2bfe9160a104378e5a344028e4ab78")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cryptominisat
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("cryptominisat5", :cryptominisat5),
    ExecutableProduct("cryptominisat5_simple", :cryptominisat5_simple),
    LibraryProduct("libcryptominisat5", :libcryptominisat5)
    
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"),
    Dependency("Zlib_jll"),
    Dependency("SQLite_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
