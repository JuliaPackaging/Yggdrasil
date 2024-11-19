# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MLX"
version = v"0.20.0"

sources = [
    GitSource("https://github.com/ml-explore/mlx.git", "726dbd926770b7c78cd23480e71f1a21c07a9bc0"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
    # Using the PyPI wheel for aarch64-apple-darwin to get the metal backend, which requires the `metal` compiler to build (which is practically impossible to use from the BinaryBuilder build env.)
    FileSource("https://files.pythonhosted.org/packages/93/07/57feaad207d1ce0d690d255cda0c35b9246911cc24f2f3c0634000ed658f/mlx-0.20.0-cp313-cp313-macosx_13_0_arm64.whl", "7d6fc39d36464d07fca0469619b01eb08e6dda19610f26bbe03703079c445abf"; filename = "mlx-aarch64-apple-darwin20.whl"),
    DirectorySource("./bundled"),
]

script = raw"""
apk del cmake # Need CMake >= 3.24

if [[ "$target" == *-apple-darwin* ]]; then
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX14.0.sdk
    sed -i "s!/opt/$bb_target/$bb_target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    sed -i "s!/opt/$bb_target/$bb_target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
fi

cd $WORKSPACE/srcdir/mlx

atomic_patch -p1 ../patches/cmake_system_processor-arm64-aarch64.patch

if [[ "$target" == *-w64-mingw32* ]]; then
    atomic_patch -p1 ../patches/cmake-w64-mingw32.patch
fi

if [[ "$target" == *-linux-musl* ||
      "$target" == *-w64-mingw32* ]]; then
    atomic_patch -p1 ../patches/musl.patch
fi

CMAKE_EXTRA_OPTIONS=()
if [[ "$target" == x86_64-apple-darwin* ]]; then
    CMAKE_EXTRA_OPTIONS+=("-DMLX_ENABLE_X64_MAC=ON")
    export MACOSX_DEPLOYMENT_TARGET=10.15
elif [[ "$target" == *-freebsd* ||
        "$target" == *-w64-mingw32* ]]; then
    CMAKE_EXTRA_OPTIONS+=(
        "-DMLX_BUILD_GGUF=OFF" # Disabled gguf, due to `gguflib-src/gguflib.c:4:10: fatal error: sys/mman.h: No such file or directory`
        "-DMLX_BUILD_SAFETENSORS=OFF" # Disabled safetensors, due to `mlx/io/safetensors.cpp.obj:safetensors.cpp:(.rdata$.refptr._ZTVN3mlx4core2io18ParallelFileReaderE[.refptr._ZTVN3mlx4core2io18ParallelFileReaderE]+0x0): undefined reference to `vtable for mlx::core::io::ParallelFileReader'`
    )
fi

install_license LICENSE

if [[ "$target" != aarch64-apple-darwin* ]]; then
    cmake \
        -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
        -DMLX_BUILD_TESTS=OFF \
        -DMLX_BUILD_EXAMPLES=OFF \
        -DMLX_BUILD_METAL=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -G Ninja \
        ${CMAKE_EXTRA_OPTIONS[@]}
    cmake --build build --parallel $nproc
    cmake --install build
    cmake --install build --component headers
else
    cd $WORKSPACE/srcdir
    unzip -d mlx-$target mlx-$target.whl
    cd mlx-$target/mlx
    find lib -type f -name "*.$dlext" | xargs -Isrc install -D -m 755 -v src $prefix/src
    find lib -type f -name "*.metallib" | xargs -Isrc install -D -m 644 -v src $prefix/src
    # MLX includes metal-cpp, which could also be distributed separately, but it is assumed to be present by cmake in MLX_C.
    find {include,share} -type f | xargs -Isrc install -D -m 644 -v src $prefix/src
fi
"""

platforms = supported_platforms()
filter!(!Sys.isfreebsd, platforms) # FreeBSD build fails, likely due to a few missing header includes, e.g.: mlx/io.h:16:10: error: no member named 'unordered_map' in namespace 'std'
platforms = expand_cxxstring_abis(platforms)

products = Product[
    FileProduct("include/mlx/mlx.h", :mlx_mlx_h),
    LibraryProduct(["libmlx", "mlx"], :libmlx),
]

dependencies = [
    Dependency("dlfcn_win32_jll"; platforms = filter(Sys.iswindows, platforms)),
    Dependency("OpenBLAS32_jll"; platforms = filter(p -> p != Platform("aarch64", "macos"), platforms)),
    HostBuildDependency(PackageSpec(name="CMake_jll")),  # Need CMake >= 3.24
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version = v"10", # C++-17, with std::reduce, required
)
