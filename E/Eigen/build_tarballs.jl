using BinaryBuilder

name = "Eigen"
version = v"3.3.7"

sources = [
    ArchiveSource("https://gitlab.com/libeigen/eigen/-/archive/$(version)/eigen-$(version).tar.bz2",
                  "685adf14bd8e9c015b78097c1dc22f2f01343756f196acdc76a678e1ae352e11")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/eigen-*

mkdir build
cd build/

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
    -DCMAKE_Fortran_COMPILER=/opt/${MACHTYPE}/bin/${MACHTYPE}-gfortran \
    ..
make -j${nproc}
make install
cd ..
cp cmake/FindEigen3.cmake ${prefix}/share/eigen3/cmake/
install_license COPYING.*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
# No products: Eigen is a pure header library
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
