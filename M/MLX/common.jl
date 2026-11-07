sources = [
    GitSource("https://github.com/ml-explore/mlx.git", "36969c094354086e15d2a327a9c50feb20b9cf11"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
    # Using the PyPI wheel of the Metal backend for aarch64-apple-darwin, which would otherwise require the `metal` compiler to build (which is practically impossible to use from the BinaryBuilder build env.)
    FileSource("https://files.pythonhosted.org/packages/77/24/7e5b7ed5d28abacab4577c7a8dd1fca6e9058504f5f95ae4333c09420e2e/mlx_metal-$(version)-py3-none-macosx_14_0_arm64.whl", "8019b2db622599267d66cc168b2f0dbf5af929790a6c3b3913e00eabc42a7947"; filename = "mlx-aarch64-apple-darwin20.whl"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
apk del cmake # Need CMake >= 3.30 for BLA_VENDOR=libblastrampoline

if [[ "$target" == *-apple-darwin* ]]; then
    sdk_root=$WORKSPACE/srcdir/MacOSX14.0.sdk
    sed -i "s#/opt/$bb_target/$bb_target/sys-root#$sdk_root#" $CMAKE_TARGET_TOOLCHAIN
    sed -i "s#/opt/$bb_target/$bb_target/sys-root#$sdk_root#" /opt/bin/$bb_full_target/$target-clang*
fi

cd $WORKSPACE/srcdir/mlx

# Use the given BLAS vendor (libblastrampoline) on Windows, rather than prebuilt OpenBLAS binaries
atomic_patch -p1 ../patches/windows-bla-vendor.patch
# Use the shell of the host, rather than PowerShell, to generate the CPU JIT preamble when cross-compiling for Windows
atomic_patch -p1 ../patches/mingw-preamble-shell.patch
# Declare IPPROTO_TCP, which is not declared by <netinet/tcp.h> on FreeBSD, cf. https://github.com/ml-explore/mlx/pull/4846
atomic_patch -p1 ../patches/freebsd-ipproto.patch

CMAKE_EXTRA_OPTIONS=()
if [[ "$target" == x86_64-apple-darwin* ]]; then
    CMAKE_EXTRA_OPTIONS+=(
        "-DCMAKE_CXX_FLAGS=-Wno-psabi -Wno-elaborated-enum-base" # Disabled psabi warnings, due to a lot being produced for mlx/backend/cpu/simd/accelerate_simd.h, and errors for CF_ENUM in the headers of the macOS 14 SDK
        -DMLX_ENABLE_X64_MAC=ON
    )
    export MACOSX_DEPLOYMENT_TARGET=13.3
elif [[ "$target" == *-w64-mingw32* ]]; then
    CMAKE_EXTRA_OPTIONS+=(
        -DMLX_BUILD_GGUF=OFF # Disabled gguf, due to `gguflib-src/gguflib.c:4:10: fatal error: sys/mman.h: No such file or directory`
    )
fi

libblastrampoline_target=$(echo $bb_full_target | cut -d- -f 1-3)
if [[ "$target" != *-apple-darwin* &&
      "$target" != aarch64-unknown-freebsd* &&
      "$libblastrampoline_target" != armv6l-linux-* ]]; then
    if [[ "$target" == *-freebsd* ]]; then
        libblastrampoline_target=$rust_target
    fi
    CMAKE_EXTRA_OPTIONS+=(
        -DBLA_VENDOR=libblastrampoline
        -DBLAS_INCLUDE_DIRS=$includedir/libblastrampoline/LP64/$libblastrampoline_target
        -DLAPACK_INCLUDE_DIRS=$includedir/libblastrampoline/LP64/$libblastrampoline_target
    )
fi

if [[ $bb_full_target == *cuda* ]]; then
    cuda_version=$(echo $bb_full_target | sed -E 's/.*-cuda\+([0-9]+\.[0-9]+).*/\1/')
    # Binaries for an arch also run on later GPUs of the same major (e.g. sm_80 on sm_86 and sm_89), except
    # for arch-specific ("a") ones, and the last arch is also included as PTX for future GPUs
    if [[ $cuda_version == "12.0" ]]; then
        cuda_archs="60-real;70-real;75-real;80-real;90a-real;90-virtual"
    elif [[ $cuda_version == "12.8" ]]; then
        cuda_archs="60-real;70-real;75-real;80-real;90a-real;100a-real;120a-real;120-virtual"
    elif [[ $cuda_version == "12.9" ]]; then
        cuda_archs="60-real;70-real;75-real;80-real;90a-real;100a-real;103a-real;120a-real;121a-real;120-virtual"
    elif [[ $cuda_version == "13.0" ]]; then
        # CUDA 13 dropped sm_60 and sm_70
        cuda_archs="75-real;80-real;90a-real;100a-real;103a-real;120a-real;121a-real;120-virtual"
    else
        false # Fail for unexpected CUDA version
    fi
    if [[ $bb_full_target == *cuda_platform+jetson* ]]; then
        cuda_archs="87-real;87-virtual" # Jetson Orin, the only Jetson supported by CUDA 12
    elif [[ $target == aarch64-* && $cuda_version == 13.* ]]; then
        cuda_archs="87-real;110a-real;$cuda_archs" # Jetson Orin and Thor, as CUDA 13 has a single aarch64 toolkit
    fi

    export CUDA_PATH=$prefix/cuda
    ln -s $prefix/cuda/lib $prefix/cuda/lib64

    CMAKE_EXTRA_OPTIONS+=(
        -DMLX_BUILD_CUDA=ON
        -DMLX_CUDA_ARCHITECTURES=$cuda_archs
        -DCUDNN_INCLUDE_PATH=$includedir # cuDNN from CUDNN_jll
        -DCUDNN_LIBRARY_PATH=$libdir
    )
fi

if [[ $bb_full_target == *cuda* && $target != x86_64-linux-gnu* ]]; then
    # Add /usr/lib/csl-glibc-x86_64 to LD_LIBRARY_PATH to be able to run host `nvcc`/`ptxas`/`fatbinary`
    # while keeping the default /usr/lib/csl-musl-x86_64,
    export LD_LIBRARY_PATH=/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:$LD_LIBRARY_PATH

    # Make sure the host CUDA executables are used by copying from the host (x86_64) nvcc redist
    NVCC_DIR=(/workspace/srcdir/cuda_nvcc-linux-$(arch)-${cuda_version}*-archive)
    rm -rfv $prefix/cuda/bin
    cp -av ${NVCC_DIR}/bin $prefix/cuda/bin
    
    rm -rfv $prefix/cuda/nvvm/bin
    cp -av ${NVCC_DIR}/nvvm/bin $prefix/cuda/nvvm/bin
fi

install_license LICENSE

if [[ "$target" != aarch64-apple-darwin* ]]; then
    cmake \
        --compile-no-warning-as-error \
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

if [[ $bb_full_target == *cuda* ]]; then
    unlink $prefix/cuda/lib64
fi
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

accelerate_platforms = filter(Sys.isapple, platforms)
openblas_platforms = filter(p ->
    arch(p) == "aarch64" && Sys.isfreebsd(p) || # aarch64-unknown-freebsd using libblastrampoline fails to compile: mlx/backend/common/lapack.h:17:10: fatal error: 'cblas.h' file not found
    arch(p) == "armv6l", # armv6l-linux using libblastrampoline fails to compile: mlx/backend/common/lapack.h:17:10: fatal error: cblas.h: No such file or directory
    filter(p -> p ∉ accelerate_platforms, platforms)
)
libblastrampoline_platforms = filter(p -> p ∉ union(accelerate_platforms, openblas_platforms), platforms)

products = Product[
    FileProduct("include/mlx/mlx.h", :mlx_mlx_h),
    LibraryProduct(["libmlx", "mlx"], :libmlx),
]

dependencies = [
    Dependency("libblastrampoline_jll"; compat="5.4", platforms = libblastrampoline_platforms),
    Dependency("OpenBLAS32_jll"; platforms = openblas_platforms),
    Dependency("OpenMPI_jll"; compat="4.1.8, 5"), # OpenMPI 5 is ABI compatible with OpenMPI 4
    HostBuildDependency(PackageSpec(name="CMake_jll")), # Need CMake >= 3.30 for BLA_VENDOR=libblastrampoline
]

julia_compat="1.9"

preferred_gcc_version = v"11" # v11: C++20, with `__builtin_cpu_supports("f16c")`, required
