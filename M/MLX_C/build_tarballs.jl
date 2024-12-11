# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MLX_C"
version = v"0.1.0"

sources = [
    GitSource("https://github.com/ml-explore/mlx-c.git", "e8889ddf56b3bd734eb79d5e5b13586a39c01403"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
    DirectorySource("./bundled"),
]

script = raw"""
if [[ "$target" == *-apple-darwin* ]]; then
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX14.0.sdk
    sed -i "s!/opt/$bb_target/$bb_target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    sed -i "s!/opt/$bb_target/$bb_target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++

    export MACOSX_DEPLOYMENT_TARGET=13.3
fi

cd $WORKSPACE/srcdir/mlx-c

atomic_patch -p1 ../patches/cmake-win32.patch

if [[ "$target" == *-w64-mingw32* ]]; then
    atomic_patch -p1 ../patches/cmake-win32-io.patch
fi

cmake \
    -B build \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
    -DMLX_C_BUILD_EXAMPLES=OFF \
    -DMLX_C_USE_SYSTEM_MLX=ON \
    -G Ninja
cmake --build build --parallel $nproc
cmake --install build
install_license LICENSE
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = Product[
    FileProduct("include/mlx/c/mlx.h", :mlx_c_mlx_h),
    LibraryProduct(["libmlxc", "mlxc"], :libmlxc),
]

dependencies = [
    BuildDependency("dlfcn_win32_jll"; platforms = filter(Sys.iswindows, platforms)),
    Dependency("MLX_jll"; compat = "0.21")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.9",
    preferred_gcc_version = v"10", # Required for arm_bf16.h
)
