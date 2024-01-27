using BinaryBuilder, Pkg

name = "Cares"
version = v"1.26.0"

# url = "https://c-ares.org/"
# description = "C library for asynchronous DNS requests (including name resolves)"

sources = [
    ArchiveSource("https://c-ares.org/download/c-ares-$(version).tar.gz",
                  "bed58c4f02b009080ebda6c2467ba469722ac6aebbf4497dc44a83d8c6194e50"),
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
