# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LLVMOpenMP"
version = v"13.0.1"

sources = [
    ArchiveSource(
        "https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/openmp-$(version).src.tar.xz",
        "6b79261371616c31fea18cd3ee1797c79ee38bcaf8417676d4fa366a24c96b4f"
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openmp-*/
# https://github.com/msys2/MINGW-packages/blob/d440dcb738/mingw-w64-clang/0901-cast-to-make-gcc-happy.patch
atomic_patch -p1 ../patches/0901-cast-to-make-gcc-happy.patch

platform_config=()
if [[ "${target}" == *-freebsd* ]]; then
    platform_config+=(-DCMAKE_SHARED_LINKER_FLAGS="-Wl,--version-script=$(pwd)/runtime/src/exports_so.txt")
elif [[ "${target}" == *-mingw* ]]; then
    apk add uasm --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing
    # backport https://gitlab.kitware.com/cmake/cmake/-/commit/78f758a463516a78a9ec8d472080c6e61cb89c7f
    sed -i "s@/c  */Fo@-c -Fo@" /usr/share/cmake/Modules/CMakeASM_MASMInformation.cmake
    sed -i "s@libomp_append(asmflags_local /@libomp_append(asmflags_local -@" runtime/cmake/LibompHandleFlags.cmake
    if [[ "${target}" == *x86_64* ]]; then
        platform_config+=(-DLIBOMP_ASMFLAGS="-win64")
    fi
    platform_config+=(-DCMAKE_ASM_MASM_COMPILER="uasm")
fi
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DLIBOMP_INSTALL_ALIASES=OFF \
    "${platform_config[@]}" \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libomp", :libomp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
