using BinaryBuilder

name = "Eigen"
version = v"3.4.1"

sources = [
    GitSource("https://gitlab.com/libeigen/eigen.git",
              "b66188b5dfd147265bfa9ec47595ca0db72d21f5")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/eigen

# We want to build Eigen as header-only library, and we thus have to disable BLAS and LAPACK which are not header-only.
cmakeflags=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN}
    -DEIGEN_BUILD_BLAS=OFF
    -DEIGEN_BUILD_DEMOS=OFF
    -DEIGEN_BUILD_LAPACK=OFF
)
cmake -Bbuild "${cmakeflags[@]}"
cmake --build build --parallel ${nprocs}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
# No products: Eigen is a pure header library
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
