# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LLVMOpenMP"
version = v"18.1.7"

sources = [
    ArchiveSource(
        "https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/openmp-$(version).src.tar.xz",
        "6523c898d754d466b77b64ddca8fd0185c5aeb7f24260ddb0fae5779eb31cee3"
    ),
    # we need a bunch of additional cmake files to build the subproject separately
    # see: https://github.com/llvm/llvm-project/issues/53281#issuecomment-1260187944
    ArchiveSource(
        "https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/cmake-$(version).src.tar.xz",
        "f0b67599f51cddcdbe604c35b6de97f2d0a447e18b9c30df300c82bf1ee25bd7"
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openmp-*/
mv ../cmake-* ../cmake
# https://github.com/msys2/MINGW-packages/blob/d440dcb738/mingw-w64-clang/0901-cast-to-make-gcc-happy.patch
atomic_patch -p1 ../patches/0901-cast-to-make-gcc-happy.patch

platform_config=()
if [[ "${target}" == *-mingw* ]]; then
    # backport https://gitlab.kitware.com/cmake/cmake/-/commit/78f758a463516a78a9ec8d472080c6e61cb89c7f
    sed -i "s@/c  */Fo@-c -Fo@" /usr/share/cmake/Modules/CMakeASM_MASMInformation.cmake
    sed -i "s@libomp_append(asmflags_local /@libomp_append(asmflags_local -@" runtime/cmake/LibompHandleFlags.cmake
    if [[ "${target}" == *x86_64* ]]; then
        platform_config+=(-DLIBOMP_ASMFLAGS="-win64")
    fi
    platform_config+=(-DCMAKE_ASM_MASM_COMPILER="uasm")
elif [[ "${target}" == aarch64-apple-* ]]; then
    # Linking libomp requires the function `__divdc3`, which is implemented in
    # `libclang_rt.osx.a` from LLVM compiler-rt.
    platform_config+=(-DCMAKE_SHARED_LINKER_FLAGS="-L${libdir}/darwin -lclang_rt.osx")
fi
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DLIBOMP_INSTALL_ALIASES=OFF \
    -DOPENMP_ENABLE_LIBOMPTARGET=OFF \
    "${platform_config[@]}" \
    ..
make -j${nproc}
make install

install_license ../LICENSE.TXT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libomp", :libomp),
]

llvm_version = v"13.0.1+1"
# Dependencies that must be installed before this package can be built
dependencies = [
    # We use UASM only for Windows
    HostBuildDependency(PackageSpec(name="UASM_jll", uuid="bbf38c07-751d-5a2b-a7fc-5c0acd9bd57e")),
    # We need libclang_rt.osx.a for linking libomp, because this library provides the
    # implementation of `__divdc3`.
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version);
                    platforms=[Platform("aarch64", "macos")]),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # Note: GCC 9 is needed to work around https://github.com/llvm/llvm-project/issues/55006
               # (failing compilation for i686 platforms with GCC 8).
               julia_compat="1.6", preferred_gcc_version=v"9", preferred_llvm_version=llvm_version)
