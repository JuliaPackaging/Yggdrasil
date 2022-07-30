# We want to exit the program if errors occur.
set -o errexit

if [[ ${target} == *mingw32* ]]; then
    export CCACHE_DISABLE=true
fi

cd ${WORKSPACE}/srcdir/llvm-project/llvm
LLVM_SRCDIR=$(pwd)

# Apply all our patches
if [ -d $WORKSPACE/srcdir/llvm_patches ]; then
for f in $WORKSPACE/srcdir/llvm_patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

if [ -d $WORKSPACE/srcdir/clang_patches ]; then
cd ${WORKSPACE}/srcdir/llvm-project/clang
for f in $WORKSPACE/srcdir/clang_patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

if [ -d $WORKSPACE/srcdir/crt_patches ]; then
cd ${WORKSPACE}/srcdir/llvm-project/compiler-rt
for f in $WORKSPACE/srcdir/crt_patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

if [ -d $WORKSPACE/srcdir/libcxx_patches ]; then
cd ${WORKSPACE}/srcdir/llvm-project/libcxx
for f in $WORKSPACE/srcdir/libcxx_patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

# Patches from the monorepo
if [ -d $WORKSPACE/srcdir/patches ]; then
cd ${WORKSPACE}/srcdir/llvm-project
for f in $WORKSPACE/srcdir/patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

# The very first thing we need to do is to build llvm-tblgen for x86_64-linux-muslc
# This is because LLVM's cross-compile setup is kind of borked, so we just
# build the tools natively ourselves, directly.  :/

# Build llvm-tblgen, clang-tblgen, and llvm-config
mkdir ${WORKSPACE}/bootstrap
pushd ${WORKSPACE}/bootstrap
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=host)
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${MACHTYPE})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
if [[ "${LLVM_MAJ_VER}" -gt "11" ]]; then
    # CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm;clang;mlir')
    CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm;clang')
else
    CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm;clang')
fi
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=False)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
if [[ "${WANT_MLIR}" -eq "1" && (("${LLVM_MAJ_VER}" -eq "12" && "${LLVM_PATCH_VER}" -gt "0") || "${LLVM_MAJ_VER}" -gt "12") ]]; then
    ninja -j${nproc} llvm-tblgen clang-tblgen mlir-tblgen llvm-config
else
    ninja -j${nproc} llvm-tblgen clang-tblgen llvm-config
fi
if [[ "${WANT_MLIR}" -eq "1" ]]; then
    if [[ ("${LLVM_MAJ_VER}" -eq "12") || ("${LLVM_MAJ_VER}" -eq "13") ]]; then
        ninja -j${nproc} mlir-linalg-ods-gen
    fi
    if [[ "${LLVM_MAJ_VER}" -gt "12" ]]; then
        ninja -j${nproc} mlir-linalg-ods-yaml-gen
    fi
fi
popd

# Let's do the actual build within the `build` subdirectory
mkdir ${WORKSPACE}/build && cd ${WORKSPACE}/build

# Accumulate these flags outside CMAKE_FLAGS,
# they will be added at the end.
CMAKE_CPP_FLAGS=""
CMAKE_CXX_FLAGS=""
CMAKE_C_FLAGS=""

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
if [[ "${ASSERTS}" == "1" ]]; then
    CMAKE_FLAGS+=(-DLLVM_ENABLE_ASSERTIONS:BOOL=ON)
fi

# build for our host arch and our GPU targets NVidia and AMD
TARGETS=(host NVPTX AMDGPU)
# Add WASM and BPF for LLVM >6
if [[ "${LLVM_MAJ_VER}" != "6" ]]; then
    TARGETS+=(WebAssembly BPF)
fi
LLVM_TARGETS=$(IFS=';' ; echo "${TARGETS[*]}")
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=$LLVM_TARGETS)

# We mostly care about clang and LLVM
PROJECTS=(llvm clang clang-tools-extra compiler-rt lld)
if [[ "${WANT_MLIR}" -eq "1" && (("${LLVM_MAJ_VER}" -eq "12" && "${LLVM_PATCH_VER}" -gt "0") || "${LLVM_MAJ_VER}" -gt "12") ]]; then
    PROJECTS+=(mlir)
fi
LLVM_PROJECTS=$(IFS=';' ; echo "${PROJECTS[*]}")
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS:STRING=$LLVM_PROJECTS)

# We want a build with no bindings
CMAKE_FLAGS+=(-DLLVM_BINDINGS_LIST="" )

# Turn on ZLIB
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=ON)
# Turn off XML2
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

# Disable useless things like docs, terminfo, etc....
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=Off)
CMAKE_FLAGS+=(-DLLVM_ENABLE_TERMINFO=Off)
CMAKE_FLAGS+=(-DHAVE_HISTEDIT_H=Off)
CMAKE_FLAGS+=(-DHAVE_LIBEDIT=Off)

# We want a shared library
if [ -z "${LLVM_WANT_STATIC}" ]; then
    CMAKE_FLAGS+=(-DLLVM_BUILD_LLVM_DYLIB:BOOL=ON)
    CMAKE_FLAGS+=(-DLLVM_LINK_LLVM_DYLIB:BOOL=ON)
    # set a SONAME suffix for FreeBSD https://github.com/JuliaLang/julia/issues/32462
    CMAKE_FLAGS+=(-DLLVM_VERSION_SUFFIX:STRING="jl")
    # Aggressively symbol version (added in LLVM 13.0.1)
    CMAKE_FLAGS+=(-DLLVM_SHLIB_SYMBOL_VERSION:STRING="JL_LLVM_${LLVM_MAJ_VER}.${LLVM_MIN_VER}")
fi

if [[ "${target}" == *linux* || "${target}" == *mingw* ]]; then
    # https://bugs.llvm.org/show_bug.cgi?id=48221
    CMAKE_CXX_FLAGS+="-fno-gnu-unique"
fi

# Install things into $prefix, and make sure it knows we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=True)

# Julia expects the produced LLVM tools to be installed into tools and not bin
# We can't simply move bin to tools since on MingW64 it will also contain the shlib.
CMAKE_FLAGS+=(-DLLVM_TOOLS_INSTALL_DIR="tools")

# Also build and install utils, since we want FileCheck, and lit
CMAKE_FLAGS+=(-DLLVM_UTILS_INSTALL_DIR="tools")
CMAKE_FLAGS+=(-DLLVM_INCLUDE_UTILS=True -DLLVM_INSTALL_UTILS=True)

# Include perf/oprofile/vtune markers
if [[ "${WANT_PERF}" -eq "1" ]]; then
    if [[ ${target} == *linux* ]]; then
        CMAKE_FLAGS+=(-DLLVM_USE_PERF=1)
        CMAKE_FLAGS+=(-DLLVM_USE_OPROFILE=1)
    fi
    # if [[ ${target} == *linux* ]] || [[ ${target} == *mingw32* ]]; then
    if [[ ${target} == *linux* ]]; then # TODO only LLVM12
        CMAKE_FLAGS+=(-DLLVM_USE_INTEL_JITEVENTS=1)
    fi
fi


if [[ "${LLVM_MAJ_VER}" -ge "14" ]]; then
    CMAKE_FLAGS+=(-DLLVM_WINDOWS_PREFER_FORWARD_SLASH=False)
fi

# Tell LLVM where our pre-built tblgen tools are
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/bootstrap/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DCLANG_TABLEGEN=${WORKSPACE}/bootstrap/bin/clang-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/bootstrap/bin/llvm-config)

if [[ "${WANT_MLIR}" -eq "1" ]]; then
    if [[ ( "${LLVM_MAJ_VER}" -eq "12" && "${LLVM_PATCH_VER}" -gt "0" ) || "${LLVM_MAJ_VER}" -gt "12" ]]; then
        CMAKE_FLAGS+=(-DMLIR_TABLEGEN=${WORKSPACE}/bootstrap/bin/mlir-tblgen)
    fi
    if [[ ("${LLVM_MAJ_VER}" -eq "12") || ("${LLVM_MAJ_VER}" -eq "13") ]]; then
        CMAKE_FLAGS+=(-DMLIR_LINALG_ODS_GEN=${WORKSPACE}/bootstrap/bin/mlir-linalg-ods-gen)
    fi
    if [[ "${LLVM_MAJ_VER}" -gt "12" ]]; then
        CMAKE_FLAGS+=(-DMLIR_LINALG_ODS_YAML_GEN=${WORKSPACE}/bootstrap/bin/mlir-linalg-ods-yaml-gen)
    fi
fi

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Manually set the host triplet, as otherwise on some platforms it tries to guess using
# `ld -v`, which is hilariously wrong.
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${target})

# Most targets use the actual target string, but we disagree on `aarch64-darwin` and `arm64-darwin`
CMAKE_TARGET=${target}

if [[ "${target}" == *apple* ]]; then
    # On OSX, we need to override LLVM's looking around for our SDK
    CMAKE_FLAGS+=(-DDARWIN_macosx_CACHED_SYSROOT:STRING=/opt/${target}/${target}/sys-root)
    CMAKE_FLAGS+=(-DDARWIN_macosx_OVERRIDE_SDK_VERSION:STRING=10.8)

    # We need to link against libc++ on OSX
    CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBCXX=ON)

    # If we're building for Apple, CMake gets confused with `aarch64-apple-darwin` and instead prefers
    # `arm64-apple-darwin`.  If this issue persists, we may have to change our triplet printing.
    if [[ "${target}" == aarch64* ]]; then
        CMAKE_TARGET=arm64-${target#*-}
    fi

    if [[ "${LLVM_MAJ_VER}" -gt "12" ]]; then
        CMAKE_FLAGS+=(-DLLVM_HAVE_LIBXAR=OFF)
    fi
fi

if [[ "${target}" == *apple* ]] || [[ "${target}" == *freebsd* ]]; then
    # On clang-based platforms we need to override the check for ffs because it doesn't work with `clang`.
    export ac_cv_have_decl___builtin_ffs=yes

    # We don't use X-ray on BSD systems
    CMAKE_FLAGS+=(-DCOMPILER_RT_BUILD_XRAY=OFF)
fi

if [[ "${target}" == *mingw* ]]; then
    CMAKE_CPP_FLAGS="${CMAKE_CPP_FLAGS} -remap -D__USING_SJLJ_EXCEPTIONS__ -D__CRT__NO_INLINE"
    # Windows is case-insensitive and some dependencies take full advantage of that
    echo "BaseTsd.h basetsd.h" >> /opt/${target}/${target}/include/header.gcc
    CMAKE_FLAGS+=(-DCLANG_INCLUDE_TESTS=OFF)
fi

CMAKE_FLAGS+=(-DCOMPILER_RT_INCLUDE_TESTS=OFF)
if [[ "${target}" == *musl* ]]; then
    # Taken from https://git.alpinelinux.org/cgit/aports/tree/main/compiler-rt/APKBUILD
    CMAKE_FLAGS+=(-DCOMPILER_RT_BUILD_SANITIZERS=OFF)
    CMAKE_FLAGS+=(-DCOMPILER_RT_BUILD_XRAY=OFF)
fi

if [[ "${target}" == *freebsd* ]]; then
    # On FreeBSD, we must force even statically-linked code to have -fPIC
    CMAKE_FLAGS+=(-DCMAKE_POSITION_INDEPENDENT_CODE=TRUE)
fi

# Tell LLVM which compiler target to use, because it loses track for some reason
CMAKE_FLAGS+=(-DCMAKE_C_COMPILER_TARGET=${CMAKE_TARGET})
CMAKE_FLAGS+=(-DCMAKE_CXX_COMPILER_TARGET=${CMAKE_TARGET})
CMAKE_FLAGS+=(-DCMAKE_ASM_COMPILER_TARGET=${CMAKE_TARGET})

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]} -DCMAKE_CXX_FLAGS="${CMAKE_CPP_FLAGS} ${CMAKE_CXX_FLAGS}" -DCMAKE_C_FLAGS="${CMAKE_CPP_FLAGS} ${CMAKE_CXX_FLAGS}"
ninja -j${nproc} -vv

# Install!
ninja install

# Life is harsh on Windows and dynamic libraries are
# expected to live alongside the binaries. So we have
# to copy the *.dll from bin/ to tools/ as well...
if [[ "${target}" == *mingw* ]]; then
    cp ${prefix}/bin/*.dll ${prefix}/tools/
fi

# Work around llvm-config bug by creating versioned symlink to libLLVM
# https://github.com/JuliaLang/julia/pull/30033
if [[ "${target}" == *darwin* ]]; then
    LLVM_VER=$(${WORKSPACE}/bootstrap/bin/llvm-config --version | cut -d. -f1-2)
    ln -s libLLVM.dylib ${prefix}/lib/libLLVM-${LLVM_VER}.dylib
fi

# Lit is a python dependency and there is no proper install target
cp -r ${LLVM_SRCDIR}/utils/lit ${prefix}/tools/

install_license ${WORKSPACE}/srcdir/llvm-project/llvm/LICENSE.TXT
