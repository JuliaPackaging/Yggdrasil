using BinaryBuilder

version = v"18.1.4"
git_sha = "e6c3289804a67ea0bb6a86fadbe454dd93b8d855"

const buildscript = raw"""
# We want to exit the program if errors occur.
set -o errexit

# Increase max file descriptors
fd_lim=$(ulimit -n -H)
ulimit -n $fd_lim

if [[ ("${target}" == x86_64-apple-darwin*) ]]; then
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

cd ${WORKSPACE}/srcdir/llvm-project/llvm
LLVM_SRCDIR=$(pwd)

# Let's do the actual build within the `build` subdirectory
mkdir ${WORKSPACE}/build && cd ${WORKSPACE}/build

# Accumulate these flags outside CMAKE_FLAGS,
# they will be added at the end.
CMAKE_CPP_FLAGS=()
CMAKE_CXX_FLAGS=()
CMAKE_C_FLAGS=()

CMAKE_FLAGS=()

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
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm')
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=False)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} llvm-tblgen llvm-config
popd

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# build for our host arch
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=host)

CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS:STRING=bolt)

# We want a build with no bindings
CMAKE_FLAGS+=(-DLLVM_BINDINGS_LIST="" )

# Turn on ZLIB
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=ON)
# Turn off XML2
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

# Disable useless things like docs, terminfo, etc....
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=Off)
CMAKE_FLAGS+=(-DLLVM_ENABLE_TERMINFO=Off)
CMAKE_FLAGS+=(-DHAVE_LIBEDIT=Off)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_BENCHMARKS=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_TESTS=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_DOXYGEN=OFF)

# Change this to check if we are building with clang?
if [[ "${bb_full_target}" != *sanitize* && ( "${target}" == *linux* ) ]]; then
    # https://bugs.llvm.org/show_bug.cgi?id=48221
    CMAKE_CXX_FLAGS+=(-fno-gnu-unique)
fi

# Install things into $prefix, and make sure it knows we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=True)

# Tell LLVM where our pre-built tblgen tools are
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/bootstrap/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/bootstrap/bin/llvm-config)

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Manually set the host triplet, as otherwise on some platforms it tries to guess using
# `ld -v`, which is hilariously wrong.
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${target})

# Most targets use the actual target string, but we disagree on `aarch64-darwin` and `arm64-darwin`
CMAKE_TARGET=${target}

if [[ "${target}" == *apple* ]]; then
    # On OSX, we need to override LLVM's looking around for our SDK
    # We need to link against libc++ on OSX
    CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBCXX=ON)

    # If we're building for Apple, CMake gets confused with `aarch64-apple-darwin` and instead prefers
    # `arm64-apple-darwin`.  If this issue persists, we may have to change our triplet printing.
    if [[ "${target}" == aarch64* ]]; then
        CMAKE_TARGET=arm64-${target#*-}
    fi
fi

GCC_VERSION=$(gcc --version | head -1 | awk '{ print $3 }' | cut -d. -f1)
if [[ $version -le 10 && "${target}" == aarch64-linux* ]]; then
    CMAKE_C_FLAGS+=(-mno-outline-atomics)
    CMAKE_CPP_FLAGS+=(-mno-outline-atomics)
fi

# Tell LLVM which compiler target to use, because it loses track for some reason
CMAKE_FLAGS+=(-DCMAKE_C_COMPILER_TARGET=${CMAKE_TARGET})
CMAKE_FLAGS+=(-DCMAKE_CXX_COMPILER_TARGET=${CMAKE_TARGET})
CMAKE_FLAGS+=(-DCMAKE_ASM_COMPILER_TARGET=${CMAKE_TARGET})

# Defaults to off when crosscompiling, starting from LLVM 18
CMAKE_FLAGS+=(-DBOLT_ENABLE_RUNTIME=ON)

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]} -DCMAKE_CXX_FLAGS=\"${CMAKE_CPP_FLAGS[*]} ${CMAKE_CXX_FLAGS[*]}\" -DCMAKE_C_FLAGS=\"${CMAKE_C_FLAGS[*]}\"
ninja -j${nproc} -vv bolt

# Install!
ninja install-llvm-bolt

install_license ${WORKSPACE}/srcdir/llvm-project/bolt/LICENSE.TXT
"""

sources = [
    GitSource("https://github.com/llvm/llvm-project.git", git_sha),
    ArchiveSource(
        "https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
        "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"
    )
]

platforms = expand_cxxstring_abis(supported_platforms())
filter!(p -> arch(p) ∈ ("x86_64", "aarch64") && os(p) ∈ ("linux", "macos"), platforms)

products = [
    ExecutableProduct("llvm-bolt", :llvm_bolt),
    ExecutableProduct("llvm-boltdiff", :llvm_boltdiff),
    ExecutableProduct("llvm-bolt-heatmap", :llvm_bolt_heatmap),
    ExecutableProduct("merge-fdata", :merge_fdata),
    ExecutableProduct("perf2bolt", :perf2bolt),
]

name = "BOLT"

# Dependencies that must be installed before this package can be built
# TODO: LibXML2
dependencies = [
    Dependency("Zlib_jll"), # for LLD&LTO
]

build_tarballs(ARGS, name, version, sources, buildscript, platforms, products, dependencies;
               preferred_gcc_version=v"10", preferred_llvm_version=v"16", julia_compat="1.6")
