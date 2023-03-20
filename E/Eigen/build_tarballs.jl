using BinaryBuilder

name = "Eigen"
version = v"3.4.0"

sources = [
    GitSource("https://gitlab.com/libeigen/eigen.git",
              "3147391d946bb4b6c68edd901f2add6ac1f31f8c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/eigen
mkdir build && cd build

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_Fortran_COMPILER=/opt/${MACHTYPE}/bin/${MACHTYPE}-gfortran \
    ..
make -j${nproc}
make install
cd ..
install_license COPYING.*
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
