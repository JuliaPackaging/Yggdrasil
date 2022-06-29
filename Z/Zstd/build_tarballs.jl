using BinaryBuilder

name = "Zstd"
version = v"1.5.2"

sources = [
    ArchiveSource("https://github.com/facebook/zstd/releases/download/v$version/zstd-$version.tar.gz",
                  "7c42d56fac126929a6a85dbc73ff1db2411d04f104fae9bdea51305663a83fd0"),
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
