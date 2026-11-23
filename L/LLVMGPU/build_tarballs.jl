# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "LLVMGPU"
version = v"1.4.0"
llvm_version = v"23.1.4"

# This JLL ships `libLLVMGPU`, a shared library that statically links a patched
# upstream LLVM with the NVPTX, AMDGPU and SPIR-V back-ends, together with
# LLVM.jl's LLVMExtra. Every LLVM symbol is hidden except for the LLVM C API,
# LLVMExtra's functions and the `llvm_orc_*` functions that support JIT-compiled
# code, so that the library can be used next to Julia's own LLVM in one process,
# through LLVM.jl. It has no host target. Besides the system and compiler
# runtime libraries, it only depends on zlib.
#
# It is meant to supersede NVPTX_LLVM_Backend, AMDGPU_LLVM_Backend and
# SPIRV_LLVM_Backend, and carries the union of their patches. The package
# version is independent of the embedded LLVM's, which `LLVMGetVersion` reports
# at run time; it follows LLVMExtra_jll's, which is built from the same sources.
sources = [
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-$(llvm_version)/llvm-project-$(llvm_version).src.tar.xz",
                  "819ecf7351f1a66f76b2d701d8942faaf5faeb324cb90c9d5b090de142434bb2"),
    # LLVMExtra, and the CMake project that links the library: the same commit
    # as LLVMExtra_jll
    GitSource("https://github.com/JuliaLLVM/LLVM.jl.git",
              "baba1ea6a8b5de904bbe277ab8ba105cae908084"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
mv llvm-project-* llvm-project
LLVM_SRCDIR=${WORKSPACE}/srcdir/llvm-project/llvm
install_license ${LLVM_SRCDIR}/LICENSE.TXT

# The patches are copies of those of the back-end recipes, which describe what
# each of them does; keep them in sync. They are applied in the same order, and
# from the same directory, as there (NVPTX and SPIR-V from `llvm/`, AMDGPU from
# the monorepo root):
# - no-process-wide-handlers (all three): make LLVM's installation of
#   process-wide signal handlers and, on Windows, an unhandled-exception filter
#   a no-op. Embedded in Julia, which synchronises its threads with SIGSEGV,
#   those handlers are fatal.
# - NVPTX_LLVM_Backend: lowering allocas to the local address space, escaped
#   debug strings, ordered atomics and loads/stores before sm_70, atomic fsub as
#   fadd, and two inlined-function line info fixes. Its
#   allow-ftz-atomics-by-default patch is part of 23.1.4.
# - AMDGPU_LLVM_Backend: the i128 datalayout default (which changes the default
#   for every target, not only AMDGPU), the si-pre-emit-peephole and usub_sat
#   fixes, endpgm in divergent code, and the `i128:64` ABI name.
# - SPIRV_LLVM_Backend: building with an old macOS SDK, and its back-end fixes.
cd ${LLVM_SRCDIR}
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/no-process-wide-handlers.patch
for f in lower-allocas-to-local-as escape-debug-str-comments \
         pre-sm70-ordered-atomics pre-sm70-ordered-loads-stores atomic-fsub-to-fadd \
         reemit-inlined-at-parents line0-reinstate-inlined-at; do
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/nvptx/${f}.patch
done
for f in avoid_builtin_available minmax_i1 nested_aggregate_insertvalue \
         aggregate_extractvalue_return aggregate_member_pointee_types sitofp_signed_i1 \
         getmemscope_per_context fence_storage_class printf_unmangled \
         bool_vector_bitcast_wide fp_fast_math_default_type copysign_shader \
         fminimum_fmaximum phi_select_retyped_operands bool_switch_selector \
         loop_merge_switch_header smul_overflow_flag resort_blocks_after_loopsimplify; do
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/spirv/${f}.patch
done
cd ${WORKSPACE}/srcdir/llvm-project
for f in 214518-i128-datalayout-default 215829-amdgpu-fix-si-pre-emit-peephole-scc \
         229471-amdgpu-fix-usub-sat-lds-flat 239163-amdgpu-endpgm-divergent \
         amdgpu-i128-abi-name; do
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/amdgpu/${f}.patch
done


# LLVM's cross-compile setup is kind of borked, so build the tablegen tools
# natively ourselves, directly.
mkdir ${WORKSPACE}/bootstrap
pushd ${WORKSPACE}/bootstrap
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=host)
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${MACHTYPE})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm')
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=False)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})
cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} llvm-tblgen llvm-config
popd

# On Windows, build with the Clang/LLD toolchain: the library is linked with
# lld (GNU ld is pathologically slow producing a DLL out of large static LLVM
# archives), and mixing GCC-built archives into a Clang/LLD link is not a
# combination we want to debug.
if [[ "${target}" == *mingw* ]]; then
    TOOLCHAIN=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake
    CXX_FLAGS="-pthread"
elif [[ "${target}" == *-linux-* ]]; then
    TOOLCHAIN=${CMAKE_TARGET_TOOLCHAIN}
    # glibc treats STB_GNU_UNIQUE symbols as process-unique regardless of
    # visibility, which would let two LLVMs in one process share state. The
    # flag is GCC-only (FreeBSD and macOS build with clang, which never emits
    # such symbols).
    CXX_FLAGS="-fno-gnu-unique"
else
    TOOLCHAIN=${CMAKE_TARGET_TOOLCHAIN}
    CXX_FLAGS=""
fi

# Build the static LLVM libraries and install them, with LLVM's CMake package,
# into a staging prefix that is not shipped.
mkdir ${WORKSPACE}/build && cd ${WORKSPACE}/build
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/bootstrap/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/bootstrap/bin/llvm-config)
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${WORKSPACE}/llvm)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="${CXX_FLAGS}")
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
# Only the GPU back-ends; no host target
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD="NVPTX;AMDGPU;SPIRV")
# Only libraries; the tablegen comes from the bootstrap build
CMAKE_FLAGS+=(-DLLVM_INCLUDE_TOOLS=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_UTILS=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_TESTS=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_BENCHMARKS=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_BINDINGS=OFF)
# zlib only: no zstd, libxml2 or libedit. FORCE_ON, as LLVM otherwise silently
# builds without zlib when it doesn't find it (as with the Windows toolchain).
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=FORCE_ON)
CMAKE_FLAGS+=(-DZLIB_ROOT=${prefix})
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZSTD=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBEDIT=OFF)
cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} install

# Link the library with LLVMExtra's standalone CMake project: it whole-archives
# the libraries that define the C API (and their dependencies), and exports only
# `LLVM*` and `llvm_orc_*` symbols (version script on ELF, exported symbols list
# on macOS, generated module definition file on Windows).
cd ${WORKSPACE}/srcdir/LLVM.jl
for f in ${WORKSPACE}/srcdir/patches/llvmextra/*.patch; do
    atomic_patch -p1 ${f}
done
install_license deps/LLVMExtra/LICENSE-APACHE deps/LLVMExtra/LICENSE-MIT
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DLLVMEXTRA_STANDALONE=ON)
CMAKE_FLAGS+=(-DLLVMEXTRA_STANDALONE_NAME=LLVMGPU)
CMAKE_FLAGS+=(-DLLVM_DIR=${WORKSPACE}/llvm/lib/cmake/llvm)
CMAKE_FLAGS+=(-DZLIB_ROOT=${prefix})
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
if [[ "${target}" == *mingw* ]]; then
    # LLVM's threading uses winpthreads with this toolchain
    CMAKE_FLAGS+=(-DCMAKE_SHARED_LINKER_FLAGS="-pthread")
fi
cmake -GNinja -B build -S deps/LLVMExtra ${CMAKE_FLAGS[@]}
ninja -C build -j${nproc} install

# Show what got exported, and (on ELF) that no symbol is STB_GNU_UNIQUE, which
# would defeat the isolation.
if [[ "${target}" == *-linux-* || "${target}" == *-freebsd* ]]; then
    echo "exported symbols: $(nm -D --defined-only ${libdir}/libLLVMGPU.${dlext} | wc -l)"
    nm -D --defined-only ${libdir}/libLLVMGPU.${dlext} | grep -v ' LLVM\| llvm_orc_' || true
    echo "STB_GNU_UNIQUE symbols: $(readelf -Ws ${libdir}/libLLVMGPU.${dlext} | grep -c UNIQUE)"
elif [[ "${target}" == *-apple-* ]]; then
    echo "exported symbols: $(nm -gU ${libdir}/libLLVMGPU.${dlext} | wc -l)"
fi
"""

# The union of the platforms of the per-back-end JLLs this one supersedes.
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built.
# The library is not dlopen'ed at `__init__` time: LLVM.jl loads it with the
# flags it needs.
products = Product[
    LibraryProduct("libLLVMGPU", :libLLVMGPU; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# LLVM 22 raised its minimum macOS deployment target to 11.0, and LLVM 23's
# headers no longer compile against the older SDK's libc++.
sources, script = require_macos_sdk("11.0", sources, script)

build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.10")
