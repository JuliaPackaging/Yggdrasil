# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Thrift"
version = v"0.19.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/apache/thrift.git", "5656208a202ca0be4d4dc44125b5ca0485f91bf0"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/thrift

# Needed as https://github.com/apache/thrift/pull/2518 isn't released yet
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

mkdir build_dir && cd build_dir

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
-DCMAKE_BUILD_TYPE=Release
-DBUILD_COMPILER=ON
-DBUILD_CPP=ON
-DBUILD_PYTHON=OFF
-DBUILD_TESTING=OFF
-DBUILD_JAVASCRIPT=OFF
-DBUILD_NODEJS=OFF
-DBUILD_SHARED_LIBS=ON
-DBUILD_TUTORIALS=OFF
-DTHRIFT_COMPILER_DELPHI=OFF)

cmake .. "${CMAKE_FLAGS[@]}"

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("thrift", :thrift)
    LibraryProduct("libthrift", :libthrift)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll", compat="=1.76.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
