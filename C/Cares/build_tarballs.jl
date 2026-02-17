using BinaryBuilder, Pkg

name = "Cares"
version = v"1.33.1"

# url = "https://c-ares.org/"
# description = "C library for asynchronous DNS requests (including name resolves)"

sources = [
    GitSource("https://github.com/c-ares/c-ares",
              "27b98d96eff6122fb981e338bddef3d6a57d8d44"),
]

script = raw"""
cd $WORKSPACE/srcdir/c-ares*/

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install

install_license ../LICENSE.md
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("adig", :adig),
    ExecutableProduct("ahost", :ahost),
    LibraryProduct("libcares", :libcares),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
