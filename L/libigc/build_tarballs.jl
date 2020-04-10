# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libigc"
version = v"1.0.3586"

# IGC depends on LLVM, a custom Clang, and a Khronos tool. Instead of building these pieces
# separately, taking care to match versions and apply Intel-specific patches where needed
# (i.e. we can't re-use Julia's LLVM_jll) collect everything here and perform a monolithic,
# in-tree build with known-good versions.

# Collection of sources required to build IGC
sources = [
    ArchiveSource("https://github.com/intel/intel-graphics-compiler/archive/igc-$(version).tar.gz", "e1b558a53f49deeb5a6e826ecbfd4e4b79bcfebb86316c64020134ca6aabfe8c"),
    # use LLVM 9 as suggested in https://github.com/intel/intel-graphics-compiler/blob/master/documentation/build_ubuntu.md
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-9.0.1/llvm-project-9.0.1.tar.xz", "ea241c807e949c24615691a5271e20bcaaa404b28a5f6deb462f9c22b478489b"),
    GitSource("https://github.com/intel/opencl-clang.git", "6c384160d03b7b8eb9c0a5e5eff265aa2b0084fd"), # ocl-open-90
    GitSource("https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git", "cc7eff18ad99019adb3730437ffd577116fc116b"), # llvm_release_90
    # patches
    GitSource("https://github.com/intel/llvm-patches.git", "1c93162ab33af968c22fe1cbfb12ea87f5a25bfa"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
# move everything in places where it will get detected by the IGC build system
mv llvm-project-* llvm-project
mv llvm-project/clang llvm-project/llvm/tools/
mv opencl-clang llvm-project/llvm/projects/opencl-clang
mv SPIRV-LLVM-Translator llvm-project/llvm/projects/llvm-spirv
mv llvm-patches llvm_patches

cd intel-graphics-compiler-*
install_license LICENSE.md

# Work around compilation failures
atomic_patch -p1 ../patches/format_macros.patch
# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=86678
atomic_patch -p1 ../patches/gcc-constexpr_assert_bug.patch
# https://github.com/intel/intel-graphics-compiler/issues/125
atomic_patch -p1 -R ../patches/static_assert.patch
if [[ "${target}" == *86*-linux-musl* ]]; then
    atomic_patch -p1 ../patches/musl-concat.patch
    atomic_patch -p1 ../patches/musl-inttypes.patch
    # https://github.com/JuliaPackaging/Yggdrasil/issues/739
    sed -i '/-fstack-protector/d' IGC/CMakeLists.txt
    # https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/387
    pushd /opt/${target}/lib/gcc/${target}/*/include
    atomic_patch -p0 $WORKSPACE/srcdir/patches/musl-malloc.patch
    popd
fi

# the build system uses git
export HOME=$(pwd)
git config --global user.name "Binary Builder"
git config --global user.email "your@email.com"

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# NOTE: igc currently can't cross compile due to a variety of issues:
# - https://github.com/intel/intel-graphics-compiler/issues/131
# - https://github.com/intel/opencl-clang/issues/91
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=OFF)

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Silence developer warnings
CMAKE_FLAGS+=(-Wno-dev)

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:x86_64, libc=:musl),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("GenX_IR", :GenX_IR),
    ExecutableProduct(["iga32", "iga64"], :iga),
    LibraryProduct(["libiga32", "libiga64"], :libiga),
    LibraryProduct("libigc", :libigc),
    LibraryProduct("libigdfcl", :libigdfcl),
    # opencl-clang
    LibraryProduct("libopencl-clang", :libopencl_clang),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"5")
