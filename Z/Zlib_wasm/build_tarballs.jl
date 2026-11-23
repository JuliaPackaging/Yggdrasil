# zlib as WebAssembly static archives: a wasm build of `Zlib_jll` at the same upstream version
# (1.3.2 for Julia 1.13). Static only; the wasm64 flavour leaves out gz*, which needs file IO.
include("../../platforms/wasm.jl")

name = "Zlib_wasm"
version = v"1.3.2"
url = "https://github.com/madler/zlib.git"
hash = "da607da739fa6047df13e66a2af6b8bec7c2a498"
sources = [GitSource(url, hash)]

script = raw"""
cd ${WORKSPACE}/srcdir/zlib*
SRCS="adler32 crc32 deflate infback inffast inflate inftrees trees zutil compress uncompr"
build() { # build <flavour> <cc> <sources>
    local o=${WORKSPACE}/build-$1; mkdir -p ${o} ${prefix}/$1/lib ${prefix}/$1/include
    for s in $3; do $2 -O3 -D_LARGEFILE64_SOURCE=1 -DHAVE_HIDDEN -c ${s}.c -o ${o}/${s}.o; done
    (cd ${o} && ${WASM_AR} rcs ${prefix}/$1/lib/libz.a $(ls *.o | sort))
    cp zlib.h zconf.h ${prefix}/$1/include/
}
build wasm32-wasip1 "${WASM32_CC}" "${SRCS} gzclose gzlib gzread gzwrite"
build wasm64-unknown-unknown "${WASM64_CC}" "${SRCS}"

wasm_install_license LICENSE
wasm_manifest wasm32-wasip1 libz
wasm_manifest wasm64-unknown-unknown libz
"""

build_wasm_tarballs(ARGS, name, version, sources, script, ["libz"];
                    native_name = "Zlib_jll", native_uuid = "83775a58-1f1d-513f-b197-d71354ab007a",
                    source = url, source_hash = hash)
