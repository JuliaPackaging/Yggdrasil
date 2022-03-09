using BinaryBuilder

name = "BLST"
version = v"0.3.3"
sources = [
    ArchiveSource("https://github.com/supranational/blst/archive/v$(version).tar.gz", "ec800ed0a834f9912d8e2d664773e897b42def628adca108845f57cd56241d97"),
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
