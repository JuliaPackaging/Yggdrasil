using BinaryBuilder

name = "Eigen"
version = v"3.3.7"

sources = [
    ArchiveSource("https://bitbucket.org/eigen/eigen/get/$(version).tar.bz2",
                  "9f13cf90dedbe3e52a19f43000d71fdf72e986beb9a5436dddcd61ff9d77a3ce")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/eigen-eigen-323c052e1731

mkdir build
cd build/

cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/${target}/${target}.toolchain ..
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
