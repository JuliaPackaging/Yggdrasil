using BinaryBuilder

name = "Zstd"
version = v"1.4.2"

sources = [
    "https://github.com/facebook/zstd/releases/download/v$version/zstd-$version.tar.gz" =>
        "12730983b521f9a604c6789140fcb94fadf9a3ca99199765e33c56eb65b643c9",
    "https://github.com/facebook/zstd/releases/download/v$version/zstd-v$version-win32.zip" =>
        "430f21b1a4e006f3bfb2e97efa94deb03aadcda8c38b5f9832a0d069e4cad19e",
    "https://github.com/facebook/zstd/releases/download/v$version/zstd-v$version-win64.zip" =>
        "13e9fd7a979398a4109fedbd6dc2f25dd0f2b0fb42b9fc957ad7b837c815949d",
]

script = raw"""
if [[ ${target} == *mingw* ]]; then
    # For Windows, just use the prebuilt binaries provided by Facebook
    mkdir -p ${WORKSPACE}/destdir/bin
    cp ${WORKSPACE}/srcdir/zstd-v*-win${nbits}/dll/* ${WORKSPACE}/destdir/bin/
else
    # There should only be one directory like this
    cd $(ls -d ${WORKSPACE}/srcdir/zstd* | grep -v win)
    make -j${nproc} prefix=${prefix} install
fi
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libzstd", :libzstd)
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
