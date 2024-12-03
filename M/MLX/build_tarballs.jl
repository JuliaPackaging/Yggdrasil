# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MLX"
version = v"0.21.0"

sources = [
    GitSource("https://github.com/ml-explore/mlx.git", "974bb54ab2f8e8450f856ac215df160374080b33"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
    # Using the PyPI wheel for aarch64-apple-darwin to get the metal backend, which requires the `metal` compiler to build (which is practically impossible to use from the BinaryBuilder build env.)
    FileSource("https://files.pythonhosted.org/packages/e3/55/cfcde5014d0e8c747c431a3384f3814857af3efbecd9f543eecf7b273fb4/mlx-0.21.0-cp313-cp313-macosx_13_0_arm64.whl", "18609008b0d51b22b400df967a702163c7501fecc8cc4b861d95ca147177cd1f"; filename = "mlx-aarch64-apple-darwin20.whl"),
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

atomic_patch -p1 ../patches/missing-unordered_map-include.patch

if [[ "$target" == *-w64-mingw32* ]]; then
    atomic_patch -p1 ../patches/cmake-win32-io.patch
fi

CMAKE_EXTRA_OPTIONS=()
if [[ "$target" == x86_64-apple-darwin* ]]; then
    CMAKE_EXTRA_OPTIONS+=("-DMLX_ENABLE_X64_MAC=ON")
    export MACOSX_DEPLOYMENT_TARGET=13.3
elif [[ "$target" == *-freebsd* ||
        "$target" == *-w64-mingw32* ]]; then
    CMAKE_EXTRA_OPTIONS+=(
        "-DMLX_BUILD_GGUF=OFF" # Disabled gguf, due to `gguflib-src/gguflib.c:4:10: fatal error: sys/mman.h: No such file or directory`
        "-DMLX_BUILD_SAFETENSORS=OFF" # Disabled safetensors, due to `mlx/io/safetensors.cpp.obj:safetensors.cpp:(.rdata$.refptr._ZTVN3mlx4core2io18ParallelFileReaderE[.refptr._ZTVN3mlx4core2io18ParallelFileReaderE]+0x0): undefined reference to `vtable for mlx::core::io::ParallelFileReader'`
    )
fi

libblastrampoline_target=$(echo $bb_full_target | cut -d- -f 1-3)
if [[ "$target" != *-apple-darwin* &&
      "$libblastrampoline_target" != armv6l-linux-* &&
      "$bb_full_target" != i686-linux-gnu-cxx11 ]]; then
    if [[ "$target" == *-freebsd* ]]; then
        libblastrampoline_target=$rust_target
    fi
    CMAKE_EXTRA_OPTIONS+=(
        "-DBLAS_INCLUDE_DIRS=$includedir/libblastrampoline/LP64/$libblastrampoline_target"
        "-DLAPACK_INCLUDE_DIRS=$includedir/libblastrampoline/LP64/$libblastrampoline_target"
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
    find lib -type f -name "*.$dlext" -exec install -D -m 755 -v {} $prefix/{} \;
    find lib -type f -name "*.metallib" -exec install -D -m 644 -v {} $prefix/{} \;

    # MLX includes metal-cpp (in `include/metal-cpp`), which could also be distributed separately, but it is assumed to be present by cmake in MLX_C.
    find {include,share} -type f -exec install -D -m 644 -v {} $prefix/{} \;
fi
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

accelerate_platforms = filter(Sys.isapple, platforms)
openblas_platforms = filter(p ->
    arch(p) == "armv6l" ||
    p == Platform("i686", "Linux"; libc = "glibc", cxxstring_abi = "cxx11"),
    filter(p -> p ∉ accelerate_platforms, platforms)
)
libblastrampoline_platforms = filter(p -> p ∉ union(accelerate_platforms, openblas_platforms), platforms)

products = Product[
    FileProduct("include/mlx/mlx.h", :mlx_mlx_h),
    LibraryProduct(["libmlx", "mlx"], :libmlx),
]

dependencies = [
    Dependency("dlfcn_win32_jll"; platforms = filter(Sys.iswindows, platforms)),
    Dependency("libblastrampoline_jll"; compat="5.4", platforms = libblastrampoline_platforms),
    Dependency("OpenBLAS32_jll"; platforms = openblas_platforms),
    HostBuildDependency(PackageSpec(name="CMake_jll")),  # Need CMake >= 3.24
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.9",
    preferred_gcc_version = v"10", # C++-17, with std::reduce, required
)
