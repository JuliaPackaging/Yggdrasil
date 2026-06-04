# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SPIRV_LLVM_Backend"
version = v"22.1.7"

# Collection of sources required to build SPIRV_LLVM_Backend.
# LLVM 22 ships a single monorepo source archive (`llvm-project-X.Y.Z.src.tar.xz`).
sources = [
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/llvm-project-$(version).src.tar.xz",
                  "5cc4a3f12bba50b6bdfb4b61bdc852117a0ff2517807c3902fc13267fb93562e"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mv llvm-project-* llvm-project

cd llvm-project/llvm
LLVM_SRCDIR=$(pwd)

# Workaround for building with an old macOS SDK that lacks a working
# __builtin_available (still applicable on LLVM 22).
atomic_patch -p1 $WORKSPACE/srcdir/patches/avoid_builtin_available.patch
# https://github.com/llvm/llvm-project/pull/164175 (fixes #163777); landed on
# main after the release/22.x branch, so still needed on 22.1.7.
atomic_patch -p1 $WORKSPACE/srcdir/patches/alloca_aggregate_type.patch
# Backport of the composite-constant-arm fix from
# https://github.com/llvm/llvm-project/pull/201417 ("[SPIR-V] Lower select
# instructions with aggregate operands").
atomic_patch -p1 $WORKSPACE/srcdir/patches/select_composite_constant.patch
# Backport of https://github.com/llvm/llvm-project/pull/201523
atomic_patch -p1 $WORKSPACE/srcdir/patches/printf_format_string_lookup.patch

install_license LICENSE.TXT

# The very first thing we need to do is to build llvm-tblgen for x86_64-linux-muslc
# This is because LLVM's cross-compile setup is kind of borked, so we just
# build the tools natively ourselves, directly.  :/

# Build llvm-tblgen and llvm-config
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

# Let's do the actual build within the `build` subdirectory
mkdir ${WORKSPACE}/build && cd ${WORKSPACE}/build
CMAKE_FLAGS=()

# Tell LLVM where our pre-built tblgen tools are
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/bootstrap/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/bootstrap/bin/llvm-config)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Only build the SPIR-V back-end
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD=SPIRV)

# Turn on ZLIB
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=ON)
# Turn off XML2 and ZSTD to avoid unnecessary dependencies
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZSTD=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

# Disable useless things like docs, terminfo, etc....
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=Off)
CMAKE_FLAGS+=(-DLLVM_ENABLE_TERMINFO=Off)
CMAKE_FLAGS+=(-DHAVE_HISTEDIT_H=Off)
CMAKE_FLAGS+=(-DHAVE_LIBEDIT=Off)

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} tools/llc/install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("llc", :llc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll")
]

build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.6")
