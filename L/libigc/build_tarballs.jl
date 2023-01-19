# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libigc"
version = v"1.0.12504"#.5

# IGC depends on LLVM, a custom Clang, and a Khronos tool. Instead of building these pieces
# separately, taking care to match versions and apply Intel-specific patches where needed
# (i.e. we can't re-use Julia's LLVM_jll) collect everything here and perform a monolithic,
# in-tree build with known-good versions.

# Collection of sources required to build IGC
# NOTE: these hashes are taken from the release notes in GitHub,
#       https://github.com/intel/intel-graphics-compiler/releases
sources = [
    GitSource("https://github.com/intel/intel-graphics-compiler.git", "b8fa033f17b86949d69451643563307dab596e47"),
    GitSource("https://github.com/intel/opencl-clang.git", "363a5262d8c7cff3fb28f3bdb5d85c8d7e91c1bb"),
    GitSource("https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git", "4ef524240833abfeee1c5b9fff6b1bd53f4806b3"),
    GitSource("https://github.com/KhronosGroup/SPIRV-Tools.git", "45dd184c790d6bfc78a5a74a10c37e888b1823fa" #= sdk-1.3.204.1 =#),
    GitSource("https://github.com/KhronosGroup/SPIRV-Headers.git", "b42ba6d92faf6b4938e6f22ddd186dbdacc98d78" #= sdk-1.3.204.1 =#),
    GitSource("https://github.com/intel/vc-intrinsics.git", "b305ba31c063baa6257826cf133b5f31f9b12dfe" #= v0.7.1 =#),
    GitSource("https://github.com/llvm/llvm-project.git", "1fdec59bffc11ae37eb51a1b9869f0696bfd5312" #= llvmorg-11.1.0 =#),
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
# https://reviews.llvm.org/D64388
sed -i '/add_subdirectory/i add_definitions(-D__STDC_FORMAT_MACROS)' intel-graphics-compiler/external/llvm/llvm.cmake

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

