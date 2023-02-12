using BinaryBuilder

name = "Zstd"
version = v"1.5.4"

sources = [
    ArchiveSource("https://github.com/facebook/zstd/releases/download/v$version/zstd-$version.tar.gz",
                  "0f470992aedad543126d06efab344dc5f3e171893810455787d38347343a4424"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/zstd-*/
mkdir build-zstd && cd build-zstd
meson --cross-file="${MESON_TARGET_TOOLCHAIN}" ../build/meson/
ninja -j${nproc}
ninja install
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libzstd", :libzstd),
    ExecutableProduct("zstd", :zstd),
    ExecutableProduct("zstdmt", :zstdmt),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
