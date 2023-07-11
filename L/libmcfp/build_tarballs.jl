using BinaryBuilder

name = "libmcfp"
version = v"1.2.4"

# url = "https://github.com/mhekkel/libmcfp"
# description = "A header only library that can collect configuration options from command line arguments"

sources = [
    GitSource("https://github.com/mhekkel/libmcfp",
              "4aa95505ded43e663fd9dae61c49b08fdc6cce0c"),
]

script = raw"""
cd $WORKSPACE/srcdir/libmcfp*/
mkdir build && cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install
install_license ../LICENSE
"""

platforms = supported_platforms()

# No products, libmcfp is a header-only library
products = Product[
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
