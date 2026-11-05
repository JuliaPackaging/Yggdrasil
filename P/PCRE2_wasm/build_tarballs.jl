# PCRE2 as WebAssembly static archives, for compilers that link C into wasm modules.
# A wasm build of `PCRE2_jll`: `version` must equal the PCRE2_jll version of the Julia that compiles
# the program (10.46.0 for Julia 1.13.2, 10.47.0 for 1.13.3); error offsets differ between minors.
# Configuration as `P/PCRE2`, minus what can't exist in wasm: 8-bit only, Unicode, no JIT (sljit
# has no wasm backend), static only. Other defaults are kept so behaviour matches the native build.
include("../../platforms/wasm.jl")

name = "PCRE2_wasm"
version = v"10.46.0"
url = "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$(version.major).$(version.minor)/pcre2-$(version.major).$(version.minor).tar.bz2"
hash = "15fbc5aba6beee0b17aecb04602ae39432393aba1ebd8e39b7cabf7db883299f"
sources = [ArchiveSource(url, hash)]

script = raw"""
SRC=$(echo ${WORKSPACE}/srcdir/pcre2-*)

# wasm32-wasip1: configure, as P/PCRE2 does
W32=${WORKSPACE}/build-wasm32
mkdir -p ${W32} && cd ${W32}
${SRC}/configure --prefix=${prefix}/wasm32-wasip1 --build=${MACHTYPE} --host=wasm32-unknown-wasi \
    CC="${WASM32_CC}" AR=${WASM_AR} RANLIB=${WASM_RANLIB} NM=${WASM_NM} CFLAGS="-O3" \
    --disable-shared --enable-static --disable-pcre2grep-callout \
    --enable-pcre2-8 --disable-pcre2-16 --disable-pcre2-32 --disable-jit
make -j${nproc} libpcre2-8.la
mkdir -p ${prefix}/wasm32-wasip1/lib/pkgconfig ${prefix}/wasm32-wasip1/include
cp .libs/libpcre2-8.a ${prefix}/wasm32-wasip1/lib/
cp src/pcre2.h ${prefix}/wasm32-wasip1/include/
cp libpcre2-8.pc ${prefix}/wasm32-wasip1/lib/pkgconfig/

# wasm64: the same members, from the same generated config.h, freestanding
W64=${WORKSPACE}/build-wasm64
mkdir -p ${W64}
for m in $(${WASM_AR} t ${W32}/.libs/libpcre2-8.a); do
    f=${m#libpcre2_8_la-}; f=${f%.o}.c
    s=${SRC}/src/${f}; [ -f ${W32}/src/${f} ] && s=${W32}/src/${f}   # pcre2_chartables.c is generated
    ${WASM64_CC} -O3 -DHAVE_CONFIG_H -DPCRE2_CODE_UNIT_WIDTH=8 -I${W32}/src -I${SRC}/src \
        -fvisibility=hidden -c ${s} -o ${W64}/${f%.c}.o
done
mkdir -p ${prefix}/wasm64-unknown-unknown/lib ${prefix}/wasm64-unknown-unknown/include
(cd ${W64} && ${WASM_AR} rcs ${prefix}/wasm64-unknown-unknown/lib/libpcre2-8.a $(ls *.o | sort))
cp ${W32}/src/pcre2.h ${prefix}/wasm64-unknown-unknown/include/

wasm_install_license ${SRC}/LICENCE.md
wasm_manifest wasm32-wasip1 libpcre2-8
wasm_manifest wasm64-unknown-unknown libpcre2-8
"""

build_wasm_tarballs(ARGS, name, version, sources, script, ["libpcre2-8"];
                    native_name = "PCRE2_jll", native_uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15",
                    source = url, source_hash = hash)
