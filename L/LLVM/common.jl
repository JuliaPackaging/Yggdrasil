# LLVMBuilder -- reliable LLVM builds all the time.
using BinaryBuilder, Pkg, LibGit2
using BinaryBuilderBase: get_addable_spec, sanitize, proc_family

# Everybody is just going to use the same set of platforms

const llvm_tags = Dict(
    v"6.0.1" => "d359f2096850c68b708bc25a7baca4282945949f",
    v"8.0.1" => "19a71f6bdf2dddb10764939e7f0ec2b98dba76c9",
    v"9.0.1" => "c1a0a213378a458fbea1a5c77b315c7dce08fd05",
    v"10.0.1" => "ef32c611aa214dea855364efd7ba451ec5ec3f74",
    v"11.0.0" => "176249bd6732a8044d457092ed932768724a6f06",
    v"11.0.1" => "43ff75f2c3feef64f9d73328230d34dac8832a91",
    v"12.0.0" => "d28af7c654d8db0b68c175db5ce212d74fb5e9bc",
    v"12.0.1" => "980d2f60a8524c5546397db9e8bbb7d6ea56c1b7", # julia-12.0.1-4
    v"13.0.1" => "8a2ae8c8064a0544814c6fac7dd0c4a9aa29a7e6", # julia-13.0.1-3
    v"14.0.5" => "73db33ead13c3596f53408ad6d1de4d0f2270adb", # julia-14.0.5-3
    v"14.0.6" => "5c82f5309b10fab0adf6a94969e0dddffdb3dbce", # julia-14.0.6-3
    v"15.0.7" => "2593167b92dd2d27849e8bc331db2072a9b4bd7f", # julia-15.0.7-10
    v"16.0.6" => "4a5c1da0d268d2858def6c1aa206ac4b31956208", # julia-16.0.6-4
    v"17.0.6" => "0007e48608221f440dce2ea0d3e4f561fc10d3c6", # julia-17.0.6-5
    v"18.1.7" => "ed30d043a240d06bb6e010a41086e75713156f4f", # julia-18.1.7-2
    v"19.1.7" => "a9df916357c2fd0851df026a84f83d87efd6e212", # julia-19.1.7-1
)

const buildscript = raw"""
# We want to exit the program if errors occur.
set -o errexit

# Increase max file descriptors
fd_lim=$(ulimit -n -H)
ulimit -n $fd_lim

if [[ ("${target}" == x86_64-apple-darwin*) && ! -z "${LLVM_UPDATE_MAC_SDK}" ]]; then
    # LLVM 15 requires macOS SDK 10.14, see
    # <https://github.com/JuliaPackaging/Yggdrasil/pull/5592#issuecomment-1309525112> and
    # references therein.
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.14
    popd
fi

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${prefix}/lib/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

if [[ ${target} == *mingw32* ]]; then
    # Build system for Windows is plagued by race conditions.
    # We disable Ccache for this platform to avoid caching
    # possibly badly compiled racey code.
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

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
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
    CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm;clang;clang-tools-extra;mlir')
else
    CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm;clang;clang-tools-extra')
fi
if [[ "${LLVM_MAJ_VER}" -gt "13" ]]; then
    CMAKE_FLAGS+=(-DMLIR_BUILD_MLIR_C_DYLIB:BOOL=ON)
fi
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=False)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
if [[ ("${LLVM_MAJ_VER}" -eq "12" && "${LLVM_PATCH_VER}" -gt "0") || "${LLVM_MAJ_VER}" -gt "12" ]]; then
    ninja -j${nproc} llvm-tblgen clang-tblgen mlir-tblgen llvm-config
else
    ninja -j${nproc} llvm-tblgen clang-tblgen llvm-config
fi
if [[ ("${LLVM_MAJ_VER}" -eq "12") || ("${LLVM_MAJ_VER}" -eq "13") ]]; then
    ninja -j${nproc} mlir-linalg-ods-gen
fi
if [[ "${LLVM_MAJ_VER}" -gt "12" ]]; then
    ninja -j${nproc} mlir-linalg-ods-yaml-gen
fi
if [[ "${LLVM_MAJ_VER}" -gt "14" ]]; then
    ninja -j${nproc} clang-tidy-confusable-chars-gen clang-pseudo-gen mlir-pdll
fi
if [[ "${LLVM_MAJ_VER}" -ge "19" ]]; then
    ninja -j${nproc} mlir-src-sharder
fi
popd

# Let's do the actual build within the `build` subdirectory
mkdir ${WORKSPACE}/build && cd ${WORKSPACE}/build

# Accumulate these flags outside CMAKE_FLAGS,
# they will be added at the end.
CMAKE_CPP_FLAGS=()
CMAKE_CXX_FLAGS=()
CMAKE_C_FLAGS=()

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
if [[ "${ASSERTS}" == "1" ]]; then
    CMAKE_FLAGS+=(-DLLVM_ENABLE_ASSERTIONS:BOOL=ON)
fi

# build for our host arch and our GPU targets NVidia and AMD
TARGETS=(host)

if [[ "${target}" != *-apple-darwin* ]]; then
    TARGETS+=(AMDGPU NVPTX)
fi

# Add WASM and BPF for LLVM >6
if [[ "${LLVM_MAJ_VER}" != "6" ]]; then
    TARGETS+=(WebAssembly BPF AVR)
fi
LLVM_TARGETS=$(IFS=';' ; echo "${TARGETS[*]}")
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=$LLVM_TARGETS)

# We mostly care about clang and LLVM
PROJECTS=(llvm clang clang-tools-extra compiler-rt lld)
# Note: we disable building MLIR dylib on 32-bit archs because of <https://github.com/llvm/llvm-project/issues/61581>.
if [[ ("${LLVM_MAJ_VER}" -eq "12" && "${LLVM_PATCH_VER}" -gt "0") || "${LLVM_MAJ_VER}" -gt "12" ]]; then
    PROJECTS+=(mlir)
fi
LLVM_PROJECTS=$(IFS=';' ; echo "${PROJECTS[*]}")
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS:STRING=$LLVM_PROJECTS)

if [[ "${LLVM_MAJ_VER}" -gt "13" ]]; then
    CMAKE_FLAGS+=(-DMLIR_BUILD_MLIR_C_DYLIB:BOOL=ON)
fi

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

# We want to build LLVM with EH and RTTI
if [ ! -z "${LLVM_WANT_EH_RTTI}" ]; then
    CMAKE_FLAGS+=(-DLLVM_ENABLE_RTTI=ON)
    CMAKE_FLAGS+=(-DLLVM_ENABLE_EH=ON)
fi
# Change this to check if we are building with clang?
if [[ "${bb_full_target}" != *sanitize* && ( "${target}" == *linux* ) ]]; then
    # https://bugs.llvm.org/show_bug.cgi?id=48221
    CMAKE_CXX_FLAGS+=(-fno-gnu-unique)
fi

# Install things into $prefix, and make sure it knows we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=True)

# Julia expects the produced LLVM tools to be installed into tools and not bin
# We can't simply move bin to tools since on MingW64 it will also contain the shlib.
if [[ "${LLVM_MAJ_VER}" -ge "16" ]]; then
    CMAKE_FLAGS+=(-DCMAKE_INSTALL_BINDIR="tools")
else
    CMAKE_FLAGS+=(-DLLVM_TOOLS_INSTALL_DIR="tools")
    CMAKE_FLAGS+=(-DCLANG_TOOLS_INSTALL_DIR="tools")
fi

# Also build and install utils, since we want FileCheck, and lit
CMAKE_FLAGS+=(-DLLVM_UTILS_INSTALL_DIR="tools")
CMAKE_FLAGS+=(-DLLVM_INCLUDE_UTILS=True -DLLVM_INSTALL_UTILS=True)

# Include perf/oprofile/vtune markers
if [[ ${target} == *linux* ]]; then
    CMAKE_FLAGS+=(-DLLVM_USE_PERF=1)
#     CMAKE_FLAGS+=(-DLLVM_USE_OPROFILE=1)
fi
# if [[ ${target} == *linux* ]] || [[ ${target} == *mingw32* ]]; then
if [[ "${LLVM_MAJ_VER}" -ge "12" && ${target} == x86_64-linux* ]]; then
    # Intel VTune is available only on x86_64 architectures
    CMAKE_FLAGS+=(-DLLVM_USE_INTEL_JITEVENTS=1)
fi


if [[ "${LLVM_MAJ_VER}" -ge "14" ]]; then
    CMAKE_FLAGS+=(-DLLVM_WINDOWS_PREFER_FORWARD_SLASH=False)
fi

# Tell LLVM where our pre-built tblgen tools are
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/bootstrap/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DCLANG_TABLEGEN=${WORKSPACE}/bootstrap/bin/clang-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/bootstrap/bin/llvm-config)
if [[ ( "${LLVM_MAJ_VER}" -eq "12" && "${LLVM_PATCH_VER}" -gt "0" ) || "${LLVM_MAJ_VER}" -gt "12" ]]; then
    CMAKE_FLAGS+=(-DMLIR_TABLEGEN=${WORKSPACE}/bootstrap/bin/mlir-tblgen)
fi
if [[ ("${LLVM_MAJ_VER}" -eq "12") || ("${LLVM_MAJ_VER}" -eq "13") ]]; then
    CMAKE_FLAGS+=(-DMLIR_LINALG_ODS_GEN=${WORKSPACE}/bootstrap/bin/mlir-linalg-ods-gen)
fi
if [[ "${LLVM_MAJ_VER}" -gt "12" ]]; then
    CMAKE_FLAGS+=(-DMLIR_LINALG_ODS_YAML_GEN=${WORKSPACE}/bootstrap/bin/mlir-linalg-ods-yaml-gen)
fi
if [[ "${LLVM_MAJ_VER}" -gt "14" ]]; then
    CMAKE_FLAGS+=(-DCLANG_TIDY_CONFUSABLE_CHARS_GEN=${WORKSPACE}/bootstrap/bin/clang-tidy-confusable-chars-gen)
    CMAKE_FLAGS+=(-DCLANG_PSEUDO_GEN=${WORKSPACE}/bootstrap/bin/clang-pseudo-gen)
    CMAKE_FLAGS+=(-DMLIR_PDLL_TABLEGEN=${WORKSPACE}/bootstrap/bin/mlir-pdll)
fi
if [[ "${LLVM_MAJ_VER}" -ge "19" ]]; then
    CMAKE_FLAGS+=(-DLLVM_NATIVE_TOOL_DIR=${WORKSPACE}/bootstrap/bin)
fi

# Explicitly use our cmake toolchain file
# Windows runs out of symbols so use clang which can do some fancy things
if [[ "${target}" == *mingw* && "${LLVM_MAJ_VER}" -ge "16" ]]; then
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake)
else
    CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
fi


# Manually set the host triplet, as otherwise on some platforms it tries to guess using
# `ld -v`, which is hilariously wrong.
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${target})

# Most targets use the actual target string, but we disagree on `aarch64-darwin` and `arm64-darwin`
CMAKE_TARGET=${target}

if [[ "${target}" == *apple* ]]; then
    # On OSX, we need to override LLVM's looking around for our SDK
    CMAKE_FLAGS+=(-DDARWIN_macosx_CACHED_SYSROOT:STRING=/opt/${target}/${target}/sys-root)
    if [[ "${LLVM_MAJ_VER}" -ge "15" ]]; then
        CMAKE_FLAGS+=(-DDARWIN_macosx_OVERRIDE_SDK_VERSION:STRING="${MACOSX_DEPLOYMENT_TARGET}")
    else
        CMAKE_FLAGS+=(-DDARWIN_macosx_OVERRIDE_SDK_VERSION:STRING=10.8)
    fi
    CMAKE_FLAGS+=(-DSANITIZER_MIN_OSX_VERSION="${MACOSX_DEPLOYMENT_TARGET}")
    # We need to link against libc++ on OSX
    CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBCXX=ON)
    CMAKE_FLAGS+=(-DCOMPILER_RT_ENABLE_IOS=OFF)
    CMAKE_FLAGS+=(-DCOMPILER_RT_ENABLE_WATCHOS=OFF)
    CMAKE_FLAGS+=(-DCOMPILER_RT_ENABLE_TVOS=OFF)
    CMAKE_FLAGS+=(-DCOMPILER_RT_ENABLE_MACCATALYST=OFF)

    # If we're building for Apple, CMake gets confused with `aarch64-apple-darwin` and instead prefers
    # `arm64-apple-darwin`.  If this issue persists, we may have to change our triplet printing.
    if [[ "${target}" == aarch64* ]]; then
        CMAKE_TARGET=arm64-${target#*-}
    fi

    if [[ "${target}" == x86_64* ]]; then
        CMAKE_FLAGS+=(-DDARWIN_osx_BUILTIN_ARCHS="x86_64")
        CMAKE_FLAGS+=(-DDARWIN_osx_ARCHS="x86_64")
    fi

    if [[ "${LLVM_MAJ_VER}" -gt "12" ]]; then
        CMAKE_FLAGS+=(-DLLVM_HAVE_LIBXAR=OFF)
    fi
fi

if [[ "${LLVM_MAJ_VER}" -ge "16" ]]; then
    GCC_VERSION=$(gcc --version | head -1 | awk '{ print $3 }' | cut -d. -f1)
    if [[ $version -le 10 && "${target}" == aarch64-linux* ]]; then
        CMAKE_C_FLAGS+=(-mno-outline-atomics)
        CMAKE_CPP_FLAGS+=(-mno-outline-atomics)
    fi
fi

if [[ "${target}" == *apple* ]] || [[ "${target}" == *freebsd* ]]; then
    # On clang-based platforms we need to override the check for ffs because it doesn't work with `clang`.
    export ac_cv_have_decl___builtin_ffs=yes

    # We don't use X-ray on BSD systems
    CMAKE_FLAGS+=(-DCOMPILER_RT_BUILD_XRAY=OFF)
fi

if [[ "${target}" == *mingw* ]]; then
    CMAKE_CPP_FLAGS+=(-remap -D__USING_SJLJ_EXCEPTIONS__ -D__CRT__NO_INLINE -pthread -DMLIR_CAPI_ENABLE_WINDOWS_DLL_DECLSPEC -Dmlir_arm_sme_abi_stubs_EXPORTS)
    CMAKE_C_FLAGS+=(-pthread -DMLIR_CAPI_ENABLE_WINDOWS_DLL_DECLSPEC)
    CMAKE_FLAGS+=(-DCOMPILER_RT_BUILD_SANITIZERS=OFF)
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

#This breaks things on LLVM15 and above, but probably should be off everywhere because we only build one runtime per run
CMAKE_FLAGS+=(-DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF)

# Tell LLVM which compiler target to use, because it loses track for some reason
CMAKE_FLAGS+=(-DCMAKE_C_COMPILER_TARGET=${CMAKE_TARGET})
CMAKE_FLAGS+=(-DCMAKE_CXX_COMPILER_TARGET=${CMAKE_TARGET})
CMAKE_FLAGS+=(-DCMAKE_ASM_COMPILER_TARGET=${CMAKE_TARGET})

# Set the bug report URL to the Julia issue tracker
CMAKE_FLAGS+=(-DBUG_REPORT_URL="https://github.com/julialang/julia")

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]} -DCMAKE_CXX_FLAGS=\"${CMAKE_CPP_FLAGS[*]} ${CMAKE_CXX_FLAGS[*]}\" -DCMAKE_C_FLAGS=\"${CMAKE_C_FLAGS[*]}\"
ninja -j${nproc} -vv

# Install!
ninja install

if [[ "${LLVM_MAJ_VER}" -ge "16" ]]; then
    # We can now tell cmake to put the dlls in the right place, and the verifier doesn't find them
    if [[ "${target}" == *mingw* ]]; then
        cp -v ${prefix}/tools/*.dll ${libdir}/.
    fi
else
    # Life is harsh on Windows and dynamic libraries are
    # expected to live alongside the binaries. So we have
    # to copy the *.dll from bin/ to tools/ as well...
    if [[ "${target}" == *mingw* ]]; then
        cp -v ${libdir}/*.dll ${prefix}/tools/.
    fi
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
"""

# Also define some scripts for extraction:
const libllvmscript = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over `llvm-config`, `libLLVM` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/tools ${libdir} ${prefix}/lib ${prefix}/lib/cmake
mv -v ${LLVM_ARTIFACT_DIR}/include/llvm* ${prefix}/include/
mv -v ${LLVM_ARTIFACT_DIR}/tools/llvm-config* ${prefix}/tools/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*LLVM*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/lib/*LLVM*.a ${prefix}/lib
mv -v ${LLVM_ARTIFACT_DIR}/lib/cmake/llvm ${prefix}/lib/cmake/llvm
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full*/*
"""

const clangscript = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over `clang`, `libclang` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/bin ${libdir} ${prefix}/lib ${prefix}/tools ${prefix}/lib/cmake
mv -v ${LLVM_ARTIFACT_DIR}/include/clang* ${prefix}/include/

# LLVM isn't very reliable in choosing tools over bin even if we tell it to
# mv -v ${LLVM_ARTIFACT_DIR}/tools/clang* ${prefix}/tools/ ; true
# mv -v ${LLVM_ARTIFACT_DIR}/bin/clang* ${prefix}/tools/ ; true
find ${LLVM_ARTIFACT_DIR}/tools/ -maxdepth 1 -type f -name "clang*" -print0 -o -type l -name "clang*" -print0 | xargs -0r mv -v -t "${prefix}/tools/"
find ${LLVM_ARTIFACT_DIR}/bin/ -maxdepth 1 -type f -name "clang*" -print0 -o -type l -name "clang*" -print0 | xargs -0r mv -v -t "${prefix}/tools/"

mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/libclang*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/lib/libclang*.a ${prefix}/lib
mv -v ${LLVM_ARTIFACT_DIR}/lib/clang ${prefix}/lib/clang
mv -v ${LLVM_ARTIFACT_DIR}/lib/cmake/clang ${prefix}/lib/cmake/clang
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full*/*
"""

const mlirscript_v13 = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))
# Clear out our `${prefix}`
rm -rf ${prefix}/*
# Copy over `libMLIR` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/tools ${libdir} ${prefix}/lib ${prefix}/lib/cmake
mv -v ${LLVM_ARTIFACT_DIR}/include/mlir* ${prefix}/include/
mv -v ${LLVM_ARTIFACT_DIR}/tools/mlir* ${prefix}/tools/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*MLIR*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*mlir*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/lib/cmake/mlir ${prefix}/lib/cmake/mlir
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full*/*
"""

const mlirscript_v14 = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over `libMLIR` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/tools ${libdir} ${prefix}/lib ${prefix}/lib/cmake
mv -v ${LLVM_ARTIFACT_DIR}/include/mlir* ${prefix}/include/
mv -v ${LLVM_ARTIFACT_DIR}/tools/mlir* ${prefix}/tools/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*MLIR*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*mlir*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/lib/objects-Release ${prefix}/lib/
mv -v ${LLVM_ARTIFACT_DIR}/lib/cmake/mlir ${prefix}/lib/cmake/mlir
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full*/*
"""

const mlirscript_v15 = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over `libMLIR` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/bin ${libdir} ${prefix}/lib ${prefix}/lib/cmake
mv -v ${LLVM_ARTIFACT_DIR}/include/mlir* ${prefix}/include/
mv -v ${LLVM_ARTIFACT_DIR}/bin/mlir* ${prefix}/bin/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*MLIR*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*mlir*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/lib/objects-Release ${prefix}/lib/
mv -v ${LLVM_ARTIFACT_DIR}/lib/cmake/mlir ${prefix}/lib/cmake/mlir
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full*/*
"""

const mlirscript_v16 = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over `libMLIR` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/tools ${libdir} ${prefix}/lib ${prefix}/lib/cmake
mv -v ${LLVM_ARTIFACT_DIR}/include/mlir* ${prefix}/include/
find ${LLVM_ARTIFACT_DIR}/tools/ -maxdepth 1 -type f -name "mlir*" -print0 -o -type l -name "mlir*" -print0 | xargs -0r mv -v -t "${prefix}/tools/"
find ${LLVM_ARTIFACT_DIR}/bin/ -maxdepth 1 -type f -name "mlir*" -print0 -o -type l -name "mlir*" -print0 | xargs -0r mv -v -t "${prefix}/tools/"
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*MLIR*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*mlir*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/lib/objects-Release ${prefix}/lib/
mv -v ${LLVM_ARTIFACT_DIR}/lib/cmake/mlir ${prefix}/lib/cmake/mlir
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full*/*
"""

const lldscript = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over `lld`, `libclang` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/bin ${libdir} ${prefix}/lib ${prefix}/tools ${prefix}/lib/cmake
mv -v ${LLVM_ARTIFACT_DIR}/include/lld* ${prefix}/include/

# LLVM isn't very reliable in choosing tools over bin even if we tell it to
file_patterns=("*lld*" "wasm-ld*" "dsymutil*")
for pattern in "${file_patterns[@]}"; do
    find ${LLVM_ARTIFACT_DIR}/bin/ -maxdepth 1 -type f -name "$pattern" -print0 -o -type l -name "$pattern" -print0 | xargs -0r mv -v -t "${prefix}/tools/"
done
for pattern in "${file_patterns[@]}"; do
    find ${LLVM_ARTIFACT_DIR}/tools/ -maxdepth 1 -type f -name "$pattern" -print0 -o -type l -name "$pattern" -print0 | xargs -0r mv -v -t "${prefix}/tools/"
done

# mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/liblld*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/lib/liblld*.a ${prefix}/lib
mv -v ${LLVM_ARTIFACT_DIR}/lib/cmake/lld ${prefix}/lib/cmake/lld
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full*/*
"""

const llvmscript_v13 = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))
# Clear out our `${prefix}`
rm -rf ${prefix}/*
# Copy over everything, but eliminate things already put inside `Clang_jll` or `libLLVM_jll`:
mv -v ${LLVM_ARTIFACT_DIR}/* ${prefix}/
rm -vrf ${prefix}/include/{clang*,llvm*,mlir*}
rm -vrf ${prefix}/bin/{clang*,llvm-config,mlir*}
rm -vrf ${prefix}/tools/{clang*,llvm-config,mlir*}
rm -vrf ${libdir}/libclang*.${dlext}*
rm -vrf ${libdir}/*LLVM*.${dlext}*
rm -vrf ${libdir}/*MLIR*.${dlext}*
rm -vrf ${prefix}/lib/*LLVM*.a
rm -vrf ${prefix}/lib/libclang*.a
rm -vrf ${prefix}/lib/clang
rm -vrf ${prefix}/lib/mlir
# Move lld to tools/
mv -v "${bindir}/lld${exeext}" "${prefix}/tools/lld${exeext}"
"""

const llvmscript_v14 = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over everything, but eliminate things already put inside `Clang_jll` or `libLLVM_jll`:
mv -v ${LLVM_ARTIFACT_DIR}/* ${prefix}/
rm -vrf ${prefix}/include/{*lld*,clang*,llvm*,mlir*}
rm -vrf ${prefix}/bin/{*lld*,wasm-ld*,dsymutil*,clang*,llvm-config,mlir*}
rm -vrf ${prefix}/tools/{*lld*,wasm-ld*,dsymutil*,clang*,llvm-config,mlir*}
rm -vrf ${libdir}/libclang*.${dlext}*
rm -vrf ${libdir}/*LLD*.${dlext}*
rm -vrf ${libdir}/*LLVM*.${dlext}*
rm -vrf ${libdir}/*MLIR*.${dlext}*
rm -vrf ${prefix}/lib/*LLVM*.a
rm -vrf ${prefix}/lib/libclang*.a
rm -vrf ${prefix}/lib/clang
rm -vrf ${prefix}/lib/mlir
rm -vrf ${prefix}/lib/lld
rm -vrf {prefix}/lib/objects-Release
"""

function configure_build(ARGS, version; experimental_platforms=false, assert=false,
    git_path="https://github.com/JuliaLang/llvm-project.git",
    git_ver=llvm_tags[version], custom_name=nothing,
    custom_version=version, static=false, platform_filter=nothing,
    eh_rtti=false, update_sdk=version >= v"15")
    # Parse out some args
    if "--assert" in ARGS
        assert = true
        deleteat!(ARGS, findfirst(ARGS .== "--assert"))
    end
    sources = [
        GitSource(git_path, git_ver),
        DirectorySource("./bundled"),
    ]

    platforms = expand_cxxstring_abis(supported_platforms(; experimental=experimental_platforms))
    if version >= v"15"
        # We don't build LLVM 15 for i686-linux-musl, see
        # <https://github.com/JuliaPackaging/Yggdrasil/pull/5592#issuecomment-1430063957>:
        #     In file included from /workspace/srcdir/llvm-project/compiler-rt/lib/sanitizer_common/sanitizer_flags.h:16:0,
        #                      from /workspace/srcdir/llvm-project/compiler-rt/lib/sanitizer_common/sanitizer_common.h:18,
        #                      from /workspace/srcdir/llvm-project/compiler-rt/lib/sanitizer_common/sanitizer_platform_limits_posix.cpp:173:
        #     /workspace/srcdir/llvm-project/compiler-rt/lib/sanitizer_common/sanitizer_internal_defs.h:352:30: error: static assertion failed
        #      #define COMPILER_CHECK(pred) static_assert(pred, "")
        #                                   ^
        filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
    end
    if platform_filter !== nothing
        platforms = filter(platform_filter, platforms)
    end
    products = [
        LibraryProduct("libclang", :libclang, dont_dlopen=true),
        LibraryProduct(["LTO", "libLTO"], :liblto, dont_dlopen=true),
        ExecutableProduct("llvm-config", :llvm_config, "tools"),
        ExecutableProduct(["clang", "clang-$(version.major)"], :clang, "tools"),
        ExecutableProduct("opt", :opt, "tools"),
        ExecutableProduct("llc", :llc, "tools"),
    ]
    if !static
        push!(products, LibraryProduct(["LLVM", "libLLVM", "libLLVM-$(version.major)jl"], :libllvm, dont_dlopen=true))
    end
    if version >= v"8"
        push!(products, ExecutableProduct("llvm-mca", :llvm_mca, "tools"))
    end
    if v"12" < version < v"13"
        push!(products, LibraryProduct(["MLIRPublicAPI", "libMLIRPublicAPI"], :mlir_public, dont_dlopen=true))
    end
    if version >= v"12.0.1"
        push!(products, LibraryProduct(["MLIR", "libMLIR"], :mlir, dont_dlopen=true))
    end
    if version >= v"14"
        push!(products, LibraryProduct(["MLIR-C", "libMLIR-C"], :mlir_c, dont_dlopen=true))
    end
    if version >= v"12"
        push!(products, LibraryProduct("libclang-cpp", :libclang_cpp, dont_dlopen=true))
        push!(products, ExecutableProduct("lld", :lld, "tools"))
        push!(products, ExecutableProduct("dsymutil", :dsymutil, "tools"))
    end

    name = "LLVM_full"
    config = "LLVM_MAJ_VER=$(version.major)\nLLVM_MIN_VER=$(version.minor)\nLLVM_PATCH_VER=$(version.patch)\n"
    if static
        config *= "LLVM_WANT_STATIC=1\n"
    end
    if eh_rtti
        config *= "LLVM_WANT_EH_RTTI=1\n"
    end
    if assert
        config *= "ASSERTS=1\n"
        name = "$(name)_assert"
    end
    if custom_name !== nothing
        name = custom_name
    end
    # Dependencies that must be installed before this package can be built
    # TODO: LibXML2
    dependencies = [
        Dependency("Zlib_jll"), # for LLD&LTO
        BuildDependency("LLVMCompilerRT_jll"; platforms=filter(p -> sanitize(p) == "memory", platforms)),
    ]
    if update_sdk
        config *= "LLVM_UPDATE_MAC_SDK=1\n"
        push!(sources,
            ArchiveSource(
                "https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"))
    end
    return name, custom_version, sources, config * buildscript, platforms, products, dependencies
end

function configure_extraction(ARGS, LLVM_full_version, name, libLLVM_version=nothing;
                              experimental_platforms=false, assert=false,
                              augmentation=false, dont_dlopen=true)
    if isempty(LLVM_full_version.build)
        error("You must lock an extracted LLVM build to a particular LLVM_full build number!")
    end
    if name != "libLLVM" && (libLLVM_version === nothing || isempty(libLLVM_version.build))
        error("You must lock an extracted LLVM build to a particular libLLVM build number!")
    end
    version = VersionNumber(LLVM_full_version.major, LLVM_full_version.minor, LLVM_full_version.patch)
    compat_version = "$(version.major).$(version.minor).$(version.patch)"
    if name == "libLLVM"
        script = libllvmscript
        products = [
            LibraryProduct(["LLVM", "libLLVM", "libLLVM-$(version.major)jl"], :libllvm; dont_dlopen),
            ExecutableProduct("llvm-config", :llvm_config, "tools"),
        ]
    elseif name == "Clang"
        script = clangscript
        products = [
            LibraryProduct("libclang", :libclang; dont_dlopen),
            LibraryProduct("libclang-cpp", :libclang_cpp; dont_dlopen),
            ExecutableProduct(["clang", "clang-$(version.major)"], :clang, "tools"),
        ]
    elseif name == "MLIR"
        script = if version < v"14"
            mlirscript_v13
        elseif version < v"15"
            mlirscript_v14
        elseif version < v"16"
            mlirscript_v15
        else
            mlirscript_v16
        end
        products = [
            LibraryProduct("libMLIR", :libMLIR; dont_dlopen),
        ]
        if v"12" <= version < v"13"
            push!(products, LibraryProduct("libMLIRPublicAPI", :libMLIRPublicAPI; dont_dlopen))
        end
        if version >= v"14"
            push!(products, LibraryProduct(["MLIR-C", "libMLIR-C"], :mlir_c; dont_dlopen))
        end
    elseif name == "LLD"
        script = lldscript
        products = [
            ExecutableProduct("lld", :lld, "tools"),
            ExecutableProduct("ld.lld", :ld_lld, "tools"),      # Unix
            ExecutableProduct("ld64.lld", :ld64_lld, "tools"),  # macOS
            ExecutableProduct("lld-link", :lld_link, "tools"),  # Windows
            ExecutableProduct("wasm-ld", :wasm_ld, "tools"),    # WebAssembly

            ExecutableProduct("dsymutil", :dsymutil, "tools"),
        ]

    elseif name == "LLVM"
        script = version < v"14" ? llvmscript_v13 : llvmscript_v14
        products = [
            LibraryProduct(["LTO", "libLTO"], :liblto; dont_dlopen),
            ExecutableProduct("opt", :opt, "tools"),
            ExecutableProduct("llc", :llc, "tools"),
        ]
        if version >= v"8"
            push!(products, ExecutableProduct("llvm-mca", :llvm_mca, "tools"))
        end
        if v"12" <= version < v"14"
            push!(products, ExecutableProduct("lld", :lld, "tools"))
            push!(products, ExecutableProduct("ld.lld", :ld_lld, "tools"))
            push!(products, ExecutableProduct("ld64.lld", :ld64_lld, "tools"))
            push!(products, ExecutableProduct("lld-link", :lld_link, "tools"))
            push!(products, ExecutableProduct("wasm-ld", :wasm_ld, "tools"))
        end
    end

    platforms = supported_platforms(; experimental=experimental_platforms)
    push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))
    if version >= v"15"
        # We don't build LLVM 15 for i686-linux-musl.
        filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
    end
    if version < v"18"
        # We only have LLVM builds for AArch64 BSD starting from LLVM 18
        filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
    end
    if version < v"19.1.7"
        # We only have LLVM builds for riscv starting from LLVM 19.1.7
        filter!(p -> arch(p) != "riscv64", platforms)
    end
    platforms = expand_cxxstring_abis(platforms)

    if augmentation
        augmented_platforms = Platform[]
        for platform in platforms
            augmented_platform = deepcopy(platform)
            augmented_platform[LLVM.platform_name] = LLVM.platform(version, assert)

            should_build_platform(triplet(augmented_platform)) || continue
            push!(augmented_platforms, augmented_platform)
        end
        platforms = augmented_platforms
    end

    dependencies = BinaryBuilder.AbstractDependency[
        Dependency("Zlib_jll"), # for LLD&LTO
    ]

    # Parse out some args
    if "--assert" in ARGS
        assert = true
        deleteat!(ARGS, findfirst(ARGS .== "--assert"))
    end

    if assert
        push!(dependencies, BuildDependency(get_addable_spec("LLVM_full_assert_jll", LLVM_full_version)))
        if !augmentation
            if name in ("Clang", "LLVM", "MLIR", "LLD")
                push!(dependencies, Dependency("libLLVM_assert_jll", libLLVM_version, compat=compat_version))
            end

            name = "$(name)_assert"
        else
            if name in ("Clang", "LLVM", "MLIR", "LLD")
                push!(dependencies, Dependency("libLLVM_jll", libLLVM_version, compat=compat_version))
            end
        end
    else
        push!(dependencies, BuildDependency(get_addable_spec("LLVM_full_jll", LLVM_full_version)))
        if name in ("Clang", "LLVM", "MLIR", "LLD")
            push!(dependencies, Dependency("libLLVM_jll", libLLVM_version, compat=compat_version))
        end
    end

    return name, version, [], script, platforms, products, dependencies
end
