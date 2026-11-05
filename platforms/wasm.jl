# WebAssembly static archives of C libraries, as `<Name>_wasm` packages.
#
# BinaryBuilder has no wasm platform, and a wasm archive is the same bytes on every host, so these
# recipes are `AnyPlatform()`. They run in the ordinary x86_64-linux-musl sandbox and call the
# LLVMBootstrap clang directly with `--target`, because the `cc`/`clang` wrappers force the host
# target. The WASI sysroot (wasi-libc) and the wasm32 compiler-rt builtins come in as pinned
# sources from the wasi-sdk release whose LLVM major matches the LLVMBootstrap shard.
#
# Each package holds one directory per flavour, each self-contained:
#   wasm32-wasip1/            ILP32, against wasi-libc; consumers link wasi-sdk's libc
#   wasm64-unknown-unknown/   LP64, freestanding: wasi-libc's headers, no libc; consumers supply the
#                             symbols listed under `needs` in its manifest
# with `lib/*.a`, `include/`, `share/licenses/` and `share/wasm-provider.toml`, which names the
# native JLL it corresponds to, the archives with their sha256 and undefined symbols, and the
# source and toolchain they were built from.
#
# A package may also ship standalone wasm32 modules (`wasm32-wasip1/lib/<name>.wasm`): the library
# linked with wasi-libc into a module that imports nothing, for hosts and programs that call it as a
# separate instance with its own memory rather than linking the archive.
#
# A recipe's script runs after `wasm_script_preamble`, which defines:
#   $WASM_CLANG $WASM_AR $WASM_RANLIB $WASM_NM   LLVMBootstrap tools
#   $WASM32_CC   the compiler for wasm32-wasip1, with sysroot and builtins
#   $WASM64_CC   the compiler for freestanding wasm64
#   wasm_install_license <file>         into each flavour
#   wasm_manifest <flavour> <lib>...    writes <flavour>/share/wasm-provider.toml
using BinaryBuilder

const WASI_SDK_VERSION = "34.0"
const WASM_LLVM_VERSION = v"23.1.1"   # wasi-sdk 34 is clang 23.1.0
const WASI_SYSROOT_SHA256 = "9d813544eeebe38b7b8f2244ed591de46b6db812c6dd1a257ff9f0d2a905a2be"
const WASI_LIBCLANG_RT_SHA256 = "eee3e634dcf71aa22b1333391623cf5c9965a637dc428a27b1a858c026c587f1"
const WASM_FLAVOURS = ("wasm32-wasip1", "wasm64-unknown-unknown")

function wasm_sources()
    url = "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-$(VersionNumber(WASI_SDK_VERSION).major)"
    return [
        ArchiveSource("$(url)/wasi-sysroot-$(WASI_SDK_VERSION).tar.gz", WASI_SYSROOT_SHA256),
        ArchiveSource("$(url)/libclang_rt-$(WASI_SDK_VERSION).tar.gz", WASI_LIBCLANG_RT_SHA256),
    ]
end

"""
    wasm_script_preamble(; native_name, native_uuid, native_version, source, source_hash)

The bash that a `<Name>_wasm` recipe's script runs first. `native_*` name the JLL whose library this
is a wasm build of; `source` and `source_hash` the upstream source (URL and sha256, or git URL and commit).
"""
function wasm_script_preamble(; native_name::String, native_uuid::String, native_version::VersionNumber,
                              source::String, source_hash::String, recipe::String)
    return """
    WASM_NATIVE_NAME=$(native_name)
    WASM_NATIVE_UUID=$(native_uuid)
    WASM_NATIVE_VERSION=$(native_version)
    WASM_SOURCE=$(source)
    WASM_SOURCE_HASH=$(source_hash)
    WASM_RECIPE=$(recipe)
    WASI_SDK_VERSION=$(WASI_SDK_VERSION)
    WASI_SYSROOT_SHA256=$(WASI_SYSROOT_SHA256)
    WASI_LIBCLANG_RT_SHA256=$(WASI_LIBCLANG_RT_SHA256)
    WASM_LLVM_SHARD=$(WASM_LLVM_VERSION)
    """ * raw"""
    WASM_CLANG=/opt/${MACHTYPE}/bin/clang
    WASM_AR=/opt/${MACHTYPE}/bin/llvm-ar
    WASM_RANLIB=/opt/${MACHTYPE}/bin/llvm-ranlib
    WASM_NM=/opt/${MACHTYPE}/bin/llvm-nm
    # "clang version X (<clone path> <commit>)" -> "clang version X (llvm-project <commit>)"
    WASM_CLANG_VERSION=$(${WASM_CLANG} --version | head -1 | sed -E 's#\(.* ([0-9a-f]{40})\)#(llvm-project \1)#')
    WASM_SYSROOT=$(echo ${WORKSPACE}/srcdir/wasi-sysroot*)
    # clang finds wasm compiler-rt in its resource directory; the shard's is read-only, so use a copy
    WASM_RD=${WORKSPACE}/wasm-resource-dir
    cp -rL $(${WASM_CLANG} -print-resource-dir) ${WASM_RD}
    mkdir -p ${WASM_RD}/lib
    cp -r ${WORKSPACE}/srcdir/libclang_rt-*/wasm32-unknown-wasip1 ${WASM_RD}/lib/
    WASM32_CC="${WASM_CLANG} --target=wasm32-wasip1 --sysroot=${WASM_SYSROOT} -resource-dir=${WASM_RD}"
    # wasi-libc has no wasm64 sysroot; its wasm32 headers give LP64 types because `_Addr` is `long`
    WASM64_CC="${WASM_CLANG} --target=wasm64-unknown-unknown -ffreestanding -nostdlib -mbulk-memory -D__wasi__ -resource-dir=${WASM_RD} -isystem ${WASM_SYSROOT}/include/wasm32-wasip1"

    wasm_install_license() {
        for f in wasm32-wasip1 wasm64-unknown-unknown; do
            mkdir -p ${prefix}/${f}/share/licenses/${SRC_NAME%_wasm}
            cp "$@" ${prefix}/${f}/share/licenses/${SRC_NAME%_wasm}/
        done
        install_license "$@"
    }

    wasm_manifest() { # wasm_manifest <flavour> <lib>...
        local f=$1; shift
        local d=${prefix}/${f} abi target libc
        case ${f} in
            wasm32-wasip1) abi=wasm32-wasip1-ilp32-v0; target=wasm32-wasip1; libc="wasi-libc from wasi-sdk ${WASI_SDK_VERSION}";;
            wasm64-unknown-unknown) abi=wasm64-lp64-freestanding-v0; target=wasm64-unknown-unknown; libc="none: the consumer supplies needs";;
        esac
        # Manifest values are quoted TOML strings; heredocs keep the quotes literal inside this raw string
        cat > ${d}/share/wasm-provider.toml <<EOF
format = 1
abi = "${abi}"

[native]
name = "${WASM_NATIVE_NAME}"
uuid = "${WASM_NATIVE_UUID}"
version = "${WASM_NATIVE_VERSION}"
EOF
        for lib in "$@"; do
            local a=${d}/lib/${lib}.a
            ${WASM_NM} --defined-only -g ${a} 2>/dev/null | awk 'NF==3{print $3}' | sort -u > ${WORKSPACE}/def
            ${WASM_NM} --undefined-only ${a} 2>/dev/null | awk 'NF>=2{print $NF}' | sort -u > ${WORKSPACE}/und
            # what the archive needs from outside itself, less what wasm-ld synthesizes
            local needs=$(comm -23 ${WORKSPACE}/und ${WORKSPACE}/def | grep -vxE '__stack_pointer|__indirect_function_table|__memory_base|__table_base|__heap_base|__data_end' | sed 's/.*/"&"/' | paste -sd, -)
            cat >> ${d}/share/wasm-provider.toml <<EOF

[libraries.${lib}]
archive = "lib/${lib}.a"
sha256 = "$(sha256sum ${a} | cut -d' ' -f1)"
deps = []
exports = $(wc -l < ${WORKSPACE}/def)
needs = [${needs}]
libc = "${libc}"
EOF
        done
        cat >> ${d}/share/wasm-provider.toml <<EOF

[build]
source = "${WASM_SOURCE}"
source_hash = "${WASM_SOURCE_HASH}"
target = "${target}"
compiler = "${WASM_CLANG_VERSION}, BinaryBuilder LLVMBootstrap ${WASM_LLVM_SHARD}"
sysroot = "wasi-sysroot-${WASI_SDK_VERSION}.tar.gz, sha256 ${WASI_SYSROOT_SHA256}"
builtins = "libclang_rt-${WASI_SDK_VERSION}.tar.gz, sha256 ${WASI_LIBCLANG_RT_SHA256}"
recipe = "${WASM_RECIPE}"
EOF
        cat ${d}/share/wasm-provider.toml
    }
    """
end

"""
`FileProduct`s for each flavour's archives and manifest, and the standalone wasm32 modules. `libs`
are archive names without `.a`, `modules` module names without `.wasm` (`wasm32-wasip1/lib/<module>.wasm`).
"""
function wasm_products(libs::Vector{String}, modules::Vector{String} = String[])
    products = Product[]
    for m in modules
        push!(products, FileProduct("wasm32-wasip1/lib/$(m).wasm", Symbol(replace(m, "-" => "_"), "_wasm32_wasm")))
    end
    for (f, short) in zip(WASM_FLAVOURS, ("wasm32", "wasm64"))
        for lib in libs
            push!(products, FileProduct("$(f)/lib/$(lib).a", Symbol(replace(lib, "-" => "_"), "_", short, "_a")))
        end
        push!(products, FileProduct("$(f)/share/wasm-provider.toml", Symbol("wasm_provider_", short)))
    end
    return products
end

"""
    build_wasm_tarballs(ARGS, name, version, sources, script, libs; native_name, native_uuid,
                        source, source_hash, kwargs...)

`build_tarballs` for a `<Name>_wasm` package: `AnyPlatform`, no dependencies, the wasi-sdk sources
and the preamble added. `version` must equal the native JLL's upstream version. `modules` are the
standalone wasm32 modules the script links (see `wasm_products`).
"""
function build_wasm_tarballs(ARGS, name, version, sources, script, libs::Vector{String};
                             native_name::String, native_uuid::String, source::String, source_hash::String,
                             modules::Vector{String} = String[], kwargs...)
    recipe = joinpath(uppercase(name[1:1]), name, "build_tarballs.jl")
    preamble = wasm_script_preamble(; native_name, native_uuid, native_version = version, source, source_hash, recipe)
    return build_tarballs(ARGS, name, version, [sources; wasm_sources()], preamble * script,
                          [AnyPlatform()], wasm_products(libs, modules), Dependency[];
                          julia_compat = "1.6", preferred_llvm_version = WASM_LLVM_VERSION, kwargs...)
end
