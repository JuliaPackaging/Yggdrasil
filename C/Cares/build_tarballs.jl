using BinaryBuilder, Pkg

name = "Cares"
version = v"1.23.0"

# url = "https://c-ares.org/"
# description = "C library for asynchronous DNS requests (including name resolves)"

sources = [
    ArchiveSource("https://c-ares.org/download/c-ares-$(version).tar.gz",
                  "cb614ecf78b477d35963ebffcf486fc9d55cc3d3216f00700e71b7d4868f79f5"),
]

script = raw"""
cd $WORKSPACE/srcdir/c-ares-*/

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
