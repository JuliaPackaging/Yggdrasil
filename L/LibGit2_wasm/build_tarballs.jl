# libgit2 as a WebAssembly static archive and a standalone wasm32 module, for programs compiled to
# WebAssembly that call Julia's LibGit2 (WasmCompat's LibGit2 backend). A wasm build of `LibGit2_jll`:
# `version` must equal the LibGit2_jll version of the Julia that compiles the program (1.9.7 for
# Julia 1.13.2). Only `wasm32-wasip1`: libgit2 needs a libc and a filesystem (WASI preview 1), so
# there is no freestanding wasm64 flavour.
#
# libgit2's changes for WASI are `bundled/patches` (the `wasi-v1.9.7` branch of
# https://github.com/pankgeorg/libgit2, proposed upstream). Configuration: no threads, no TLS backend,
# no SSH (WASI has no sockets: https goes through the module's smart transport, whose requests are the
# host's fetch, `wasm_host.http_request`), bundled zlib, PCRE, llhttp, xdiff and SHA1DC.
#
# `wasm32-wasip1/lib/libgit2.wasm` is the archive, `bundled/lg2w.c` (that transport, the WASI defaults
# and a flat API for hosts) and wasi-libc linked into a reactor module. It imports WASI preview 1 (an
# instance of its own, over the program's preopens) and `wasm_host.http_request`, and exports `memory`,
# `malloc`, `free`, loads and stores by address, `lg2w_*` and the libgit2 functions in
# `bundled/exports.txt`.
include("../../platforms/wasm.jl")

name = "LibGit2_wasm"
version = v"1.9.7"
url = "https://github.com/libgit2/libgit2.git"
hash = "49e408b3208bc3093757a1c2db938d3590f3f412"   # v$(version)
sources = [GitSource(url, hash), DirectorySource("./bundled")]

script = raw"""
SRC=${WORKSPACE}/srcdir/libgit2
cd ${SRC}
for p in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${p}
done

# CMake for wasm32-wasip1 with the LLVMBootstrap clang, the WASI sysroot and the wasm builtins
cat > ${WORKSPACE}/wasi.cmake <<END_CMAKE
set(CMAKE_SYSTEM_NAME WASI)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR wasm32)
set(CMAKE_C_COMPILER ${WASM_CLANG})
set(CMAKE_C_COMPILER_TARGET wasm32-wasip1)
set(CMAKE_SYSROOT ${WASM_SYSROOT})
set(CMAKE_C_FLAGS_INIT "-resource-dir=${WASM_RD}")
set(CMAKE_AR ${WASM_AR} CACHE FILEPATH "")
set(CMAKE_RANLIB ${WASM_RANLIB} CACHE FILEPATH "")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
END_CMAKE

B=${WORKSPACE}/build-wasm32
cmake -S ${SRC} -B ${B} -DCMAKE_TOOLCHAIN_FILE=${WORKSPACE}/wasi.cmake -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DCMAKE_C_FLAGS="-ffile-prefix-map=${SRC}=libgit2-1.9.7" \
    -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF -DBUILD_CLI=OFF -DBUILD_EXAMPLES=OFF \
    -DUSE_THREADS=OFF -DUSE_HTTPS=OFF -DUSE_SSH=OFF -DUSE_GSSAPI=OFF -DUSE_NTLMCLIENT=OFF -DUSE_ICONV=OFF \
    -DUSE_SHA1=CollisionDetection -DUSE_SHA256=Builtin -DREGEX_BACKEND=builtin -DUSE_HTTP_PARSER=builtin \
    -DUSE_BUNDLED_ZLIB=ON -DUSE_NSEC=ON
make -C ${B} -j${nproc}

P=${prefix}/wasm32-wasip1
mkdir -p ${P}/lib ${P}/include
cp ${B}/libgit2.a ${P}/lib/
cp -r ${SRC}/include/git2 ${SRC}/include/git2.h ${P}/include/

# the standalone module
exports=$(sed 's/^/-Wl,--export=/' ${WORKSPACE}/srcdir/exports.txt)
${WASM32_CC} -Os -mexec-model=reactor -ffile-prefix-map=${WORKSPACE}/srcdir=lg2w -I${SRC}/include \
    -Wl,-z,stack-size=1048576 -Wl,--export=malloc -Wl,--export=free ${exports} -Wl,--strip-all \
    ${WORKSPACE}/srcdir/lg2w.c ${P}/lib/libgit2.a -o ${P}/lib/libgit2.wasm

# licences: libgit2's COPYING (GPL-2.0 with the linking exception, and the LGPL-2.1 of xdiff), the
# bundled code's, wasi-libc's (in the module)
L=${WORKSPACE}/licenses
mkdir -p ${L}
cp ${SRC}/COPYING ${L}/COPYING
cp ${SRC}/deps/zlib/LICENSE ${L}/zlib-LICENSE
cp ${SRC}/deps/pcre2/LICENCE.md ${L}/pcre2-LICENCE.md
cp ${SRC}/deps/llhttp/LICENSE-MIT ${L}/llhttp-LICENSE-MIT
cp ${WORKSPACE}/srcdir/licenses/sha1dc-LICENSE.txt ${WORKSPACE}/srcdir/licenses/README.md ${L}/
wasm_install_license ${L}/COPYING ${L}/zlib-LICENSE ${L}/pcre2-LICENCE.md ${L}/llhttp-LICENSE-MIT \
    ${L}/sha1dc-LICENSE.txt ${L}/README.md
for d in ${P}/share/licenses/LibGit2 ${prefix}/share/licenses/LibGit2_wasm; do
    mkdir -p ${d}/wasi-libc
    cp ${WORKSPACE}/srcdir/licenses/wasi-libc/* ${d}/wasi-libc/
done

# the corresponding source of the module: the patches, the wrapper and its exports (libgit2's
# tarball and this recipe are the rest)
S=${prefix}/share/src/LibGit2_wasm
mkdir -p ${S}/patches
cp ${WORKSPACE}/srcdir/patches/*.patch ${S}/patches/
cp ${WORKSPACE}/srcdir/lg2w.c ${WORKSPACE}/srcdir/exports.txt ${S}/
cat > ${S}/SOURCES.md <<END_SOURCES
# Corresponding source of libgit2.wasm and libgit2.a

- libgit2 1.9.7: ${WASM_SOURCE}, commit ${WASM_SOURCE_HASH} (tag v1.9.7)
- patches/: the commits of https://github.com/pankgeorg/libgit2/tree/wasi-v1.9.7 (git format-patch v1.9.7..wasi-v1.9.7)
- lg2w.c, exports.txt: the module's wrapper (MIT) and the libgit2 functions it exports
- the build: ${WASM_RECIPE} of Yggdrasil (BinaryBuilder, LLVMBootstrap ${WASM_LLVM_SHARD}, wasi-sysroot ${WASI_SDK_VERSION})
- the bundled dependencies (zlib, PCRE2, llhttp, xdiff, SHA1DC) are in libgit2's tarball (deps/, src/util/hash/)
END_SOURCES

wasm_manifest wasm32-wasip1 libgit2
# the module: its imports (the symbols of its undefined functions) and exports
imports=$(/opt/${MACHTYPE}/bin/llvm-objdump -t ${P}/lib/libgit2.wasm | awk '$3=="*UND*"{print $NF}' | \
    sed -e 's/^__imported_wasi_snapshot_preview1_/wasi_snapshot_preview1./' -e 's/^wasm_host_http_request$/wasm_host.http_request/' | \
    sort -u | sed 's/.*/"&"/' | paste -sd, -)
cat >> ${P}/share/wasm-provider.toml <<END_MODULE

[modules.libgit2]
module = "lib/libgit2.wasm"
sha256 = "$(sha256sum ${P}/lib/libgit2.wasm | cut -d' ' -f1)"
imports = [${imports}]
abi = "lg2w $(grep -o 'LG2W_ABI_VERSION [0-9]*' ${WORKSPACE}/srcdir/lg2w.c | cut -d' ' -f2)"
END_MODULE
cat ${P}/share/wasm-provider.toml
"""

build_wasm_tarballs(ARGS, name, version, sources, script, ["libgit2"];
                    modules = ["libgit2"], flavours = ("wasm32-wasip1",),
                    native_name = "LibGit2_jll", native_uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5",
                    source = url, source_hash = hash)
