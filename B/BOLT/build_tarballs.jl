using BinaryBuilder

version = v"23.1.2"
git_sha = "85ac560262434c9ccfc0c183ec22d4138ed647fb" # llvmorg-23.1.2

script = raw"""
# We want to exit the program if errors occur.
set -o errexit

# Increase max file descriptors
fd_lim=$(ulimit -n -H)
ulimit -n $fd_lim

cd ${WORKSPACE}/srcdir/llvm-project

# Backport of llvm/llvm-project#215415: don't relax same-function ADRs in large
# non-simple AArch64 functions, which made BOLT fail on a ThinLTO libLLVM.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/bolt-aarch64-adr-relaxation-non-simple.patch

cd llvm
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

GCC_VERSION=$(gcc --version | head -1 | awk '{ print $3 }' | cut -d. -f1)
if [[ $version -le 10 && "${target}" == aarch64-linux* ]]; then
    CMAKE_C_FLAGS+=(-mno-outline-atomics)
    CMAKE_CPP_FLAGS+=(-mno-outline-atomics)
fi

# Tell LLVM which compiler target to use, because it loses track for some reason
CMAKE_FLAGS+=(-DCMAKE_C_COMPILER_TARGET=${target})
CMAKE_FLAGS+=(-DCMAKE_CXX_COMPILER_TARGET=${target})
CMAKE_FLAGS+=(-DCMAKE_ASM_COMPILER_TARGET=${target})

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
    DirectorySource("./bundled"),
]

# BOLT only optimizes ELF binaries, so we only ship it for Linux.
platforms = expand_cxxstring_abis(supported_platforms())
filter!(p -> arch(p) ∈ ("x86_64", "aarch64") && Sys.islinux(p), platforms)

products = [
    ExecutableProduct("llvm-bolt", :llvm_bolt),
    ExecutableProduct("llvm-boltdiff", :llvm_boltdiff),
    ExecutableProduct("llvm-bolt-heatmap", :llvm_bolt_heatmap),
    ExecutableProduct("llvm-bolt-binary-analysis", :llvm_bolt_binary_analysis),
    ExecutableProduct("merge-fdata", :merge_fdata),
    ExecutableProduct("perf2bolt", :perf2bolt),
]

name = "BOLT"

# Dependencies that must be installed before this package can be built
# TODO: LibXML2
dependencies = [
    Dependency("Zlib_jll"), # for LLD&LTO
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", preferred_llvm_version=v"18", julia_compat="1.6")
