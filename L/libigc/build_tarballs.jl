# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libigc"
version = v"1.0.8744"

# IGC depends on LLVM, a custom Clang, and a Khronos tool. Instead of building these pieces
# separately, taking care to match versions and apply Intel-specific patches where needed
# (i.e. we can't re-use Julia's LLVM_jll) collect everything here and perform a monolithic,
# in-tree build with known-good versions.

# Collection of sources required to build IGC
# NOTE: these hashes are taken from the release notes in GitHub,
#       https://github.com/intel/intel-graphics-compiler/releases
# NOTE: the SPIRV-LLVM-Translator doesn't match what's in the release notes,
#       but gets checked out to $SPIRV_REV_PATCH in IGC/VectorCompiler/cmake/spirv.cmake,
#       https://github.com/intel/intel-graphics-compiler/blob/master/IGC/VectorCompiler/cmake/spirv.cmake
sources = [
    GitSource("https://github.com/intel/intel-graphics-compiler.git", "3ba8dde8c414a0e47df58b1bba12a64f8ba2089e"),
    GitSource("https://github.com/intel/opencl-clang.git", "fd68f64b33e67d58f6c36b9e25c31c1178a1962a"),
    GitSource("https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git", "d8d516efa27a8b3d9c40d8c78390c5c53c6e99d6"),
    GitSource("https://github.com/intel/vc-intrinsics.git", "e5ad7e02aa4aa21a3cd7b3e5d1f3ec9b95f58872"),
    GitSource("https://github.com/llvm/llvm-project.git", "1fdec59bffc11ae37eb51a1b9869f0696bfd5312"),
    # patches
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
# the build system uses git
export HOME=$(pwd)
git config --global user.name "Binary Builder"
git config --global user.email "your@email.com"

# move everything in places where it will get detected by the IGC build system
mv opencl-clang llvm-project/llvm/projects/opencl-clang
mv SPIRV-LLVM-Translator llvm-project/llvm/projects/llvm-spirv

# Work around compilation failures
# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=86678
atomic_patch -p0 patches/gcc-constexpr_assert_bug.patch

cd intel-graphics-compiler
install_license LICENSE.md

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
ninja -C build -j ${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux", libc="glibc"),
    Platform("x86_64", "linux", libc="glibc"),
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

# IGC only supports Ubuntu 18.04+, which uses GCC 7.4.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8", lock_microarchitecture=false)

