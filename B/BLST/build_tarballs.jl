using BinaryBuilder

name = "BLST"
version = v"0.3.1"
sources = [
    ArchiveSource("https://github.com/supranational/blst/archive/v0.3.1.tar.gz", "39f649843b8a394fd026d4945365c2065d521a82be3162cf46f3654b3227a373"),
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
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    MacOS(:x86_64),
    Windows(:x86_64),
]

products = [
    LibraryProduct("libblst", :libblst),
]

dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
