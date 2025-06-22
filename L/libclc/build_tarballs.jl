# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libclc"
version = v"20.1.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/llvm-$(version).src.tar.xz",
                  "6286c526db3b84ce79292f80118e7e6d3fbd5b5ce3e4a0ebb32b2d205233bd86"),
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/clang-$(version).src.tar.xz",
                  "65031207d088937d0ffdf4d7dd7167cae640b7c9188fc0be3d7e286a89b7787c"),
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/cmake-$(version).src.tar.xz",
                  "8a48d5ff59a078b7a94395b34f7d5a769f435a3211886e2c8bf83aa2981631bc"),
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/third-party-$(version).src.tar.xz",
                  "0eaaabff4be62189599026019f232adefc03d3db25d41f1a090ad8e806dc5dce"),
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/libclc-$(version).src.tar.xz",
                  "ea1db1c7ffd6ba524124112040458f033ee7a156d9e382e5d04e73d609f8fbed"),
    DirectorySource("bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mv llvm-* llvm
mv clang-* clang
mv cmake-* cmake
mv third-party-* third-party
mv libclc-* libclc

atomic_patch -p1 patches/124743.patch

# Build LLVM with support for the necessary targets.
# libclc really only needs clang, llvm-as, llvm-link and opt,
# but it uses find_package so really needs the whole thing installed.
cd $WORKSPACE/srcdir/llvm
mkdir bootstrap && cd bootstrap
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${host_prefix})
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING="AMDGPU;NVPTX;SPIRV")
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${MACHTYPE})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm;clang')
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=False)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZSTD=OFF)
cmake -GNinja ../ ${CMAKE_FLAGS[@]}
ninja -j${nproc} install

cd $WORKSPACE/srcdir/libclc
install_license LICENSE.TXT

mkdir build && cd build
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=True)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})
CMAKE_FLAGS+=(-DLLVM_CMAKE_DIR=$host_prefix/lib/cmake/llvm)
cmake -GNinja ../ ${CMAKE_FLAGS[@]}

ninja -j${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/clc/clc.h", :clc_h),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # XXX: can't use our LLVM JLL because it doesn't have the SPIR-V target
    #HostBuildDependency(PackageSpec(; name="LLVM_full_jll", version)),
    HostBuildDependency(PackageSpec(; name="SPIRV_LLVM_Translator_jll", version=Base.thisminor(version))),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
