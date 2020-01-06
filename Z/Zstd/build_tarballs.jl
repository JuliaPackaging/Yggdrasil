using BinaryBuilder

name = "Zstd"
version = v"1.4.4"

sources = [
    "https://github.com/facebook/zstd/releases/download/v$version/zstd-$version.tar.gz" =>
    "59ef70ebb757ffe74a7b3fe9c305e2ba3350021a918d168a046c6300aeea9315",
    "./bundled"
]

script = raw"""
cd ${WORKSPACE}/srcdir/zstd-*/
atomic_patch -p1 ../patches/timefn_h_windows.patch
mkdir build-zstd && cd build-zstd
if [[ "${target}" == aarch64-linux-gnu ]]; then
    # Work around https://github.com/facebook/zstd/issues/1872
    export CFLAGS=-D_POSIX_C_SOURCE
fi
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ../build/cmake/
make -j${nproc}
make install
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libzstd", :libzstd),
    ExecutableProduct("zstd", :zstd),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
