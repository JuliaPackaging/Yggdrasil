# OpenLibm as WebAssembly static archives: a wasm build of `OpenLibm_jll` at the same commit
# (0.8.7 for Julia 1.13). OpenLibm is freestanding in both flavours; it brings its own headers.
include("../../platforms/wasm.jl")

name = "OpenLibm_wasm"
version = v"0.8.7"
url = "https://github.com/JuliaMath/openlibm.git"
hash = "9fbeafcd4f1b6ef6aa3946c1c8faead50f38a94d"
sources = [GitSource(url, hash)]

script = raw"""
cd ${WORKSPACE}/srcdir/openlibm*
# OpenLibm's own wasm32 port (freestanding, --target=wasm32-unknown-unknown)
make -j${nproc} ARCH=wasm32 CC="${WASM_CLANG}" AR=${WASM_AR} libopenlibm.a
mkdir -p ${prefix}/wasm32-wasip1/lib ${prefix}/wasm32-wasip1/include
cp libopenlibm.a ${prefix}/wasm32-wasip1/lib/
cp include/openlibm*.h ${prefix}/wasm32-wasip1/include/
make clean

# The same port retargeted to wasm64: its freestanding headers state ILP32
sed -i 's/--target=wasm32-unknown-unknown/--target=wasm64-unknown-unknown/' Make.inc
sed -i -e 's/typedef unsigned int       uintptr_t;/typedef unsigned long      uintptr_t;/' \
       -e 's/typedef int                intptr_t;/typedef long               intptr_t;/' \
       -e 's/sizeof (uintptr_t) == 4/sizeof (uintptr_t) == 8/' wasm32/stdint.h
sed -i -e 's/#define LONG_MIN INT32_MIN/#define LONG_MIN INT64_MIN/' \
       -e 's/#define LONG_MAX INT32_MAX/#define LONG_MAX INT64_MAX/' wasm32/limits.h
make -j${nproc} ARCH=wasm32 CC="${WASM_CLANG}" AR=${WASM_AR} libopenlibm.a
mkdir -p ${prefix}/wasm64-unknown-unknown/lib ${prefix}/wasm64-unknown-unknown/include
cp libopenlibm.a ${prefix}/wasm64-unknown-unknown/lib/
cp include/openlibm*.h ${prefix}/wasm64-unknown-unknown/include/

wasm_install_license LICENSE.md
wasm_manifest wasm32-wasip1 libopenlibm
wasm_manifest wasm64-unknown-unknown libopenlibm
"""

build_wasm_tarballs(ARGS, name, version, sources, script, ["libopenlibm"];
                    native_name = "OpenLibm_jll", native_uuid = "05823500-19ac-5b8b-9628-191a04bc5112",
                    source = url, source_hash = hash)
