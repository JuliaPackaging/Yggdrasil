# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "HighFive"
version = v"2.10.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/BlueBrain/HighFive", "ede97c8d51905c1640038561d12d41da173012ac"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/HighFive
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DHIGHFIVE_UNIT_TESTS=OFF \
    -DHIGHFIVE_EXAMPLES=OFF \
    -DHIGHFIVE_BUILD_DOCS=off \
    -DHIGHFIVE_TEST_BOOST=ON \
    -DHIGHFIVE_TEST_EIGEN=ON \
    -DHIGHFIVE_TEST_HALF_FLOAT=ON \
    -DHIGHFIVE_TEST_XTENSOR=ON
# -DHIGHFIVE_TEST_OPENCV=ON
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = Product[
    # This is a header-only library without any binary products
    FileProduct("include/highfive/highfive.hpp", :highfive),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Eigen_jll"),
    BuildDependency("xtensor_jll"),
    Dependency("HDF5_jll"; compat="~1.14.0"),
    # Dependency("OpenCV_jll"),
    Dependency("boost_jll"; compat="=1.79.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
