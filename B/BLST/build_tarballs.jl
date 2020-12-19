using BinaryBuilder

name = "BLST"
version = v"0.3.2"
sources = [
    ArchiveSource("https://github.com/supranational/blst/archive/v0.3.2.tar.gz", "075f7c7f22cdf93de528ca7fa9aab53d255bf9f4e51155088d10d28e605715d9"),
]

script = raw"""
set -x
cd ${WORKSPACE}/srcdir/blst-*
export CFLAGS="-O2 -fPIC -Wall -Wextra"

if [[ "${proc_family}" == intel ]]; then
    CFLAGS="${CFLAGS} -mno-avx"
fi

mkdir -p ${libdir}
${CC} -shared -o ${libdir}/libblst.${dlext} ${CFLAGS} src/server.c build/assembly.S
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    # Platform("x86_64", "freebsd"),
    Platform("x86_64", "windows"),
]

products = [
    LibraryProduct("libblst", :libblst),
]

dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
