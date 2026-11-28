include(joinpath(@__DIR__, "..", "..", "platforms", "macos_sdks.jl"))

sources = [
    GitSource("https://github.com/ml-explore/mlx.git", "36969c094354086e15d2a327a9c50feb20b9cf11"; tag="v$(version)"),
    # Using the PyPI wheel of the Metal backend for aarch64-apple-darwin, which would otherwise require the `metal` compiler to build (which is practically impossible to use from the BinaryBuilder build env.)
    FileSource("https://files.pythonhosted.org/packages/77/24/7e5b7ed5d28abacab4577c7a8dd1fca6e9058504f5f95ae4333c09420e2e/mlx_metal-$(version)-py3-none-macosx_14_0_arm64.whl", "8019b2db622599267d66cc168b2f0dbf5af929790a6c3b3913e00eabc42a7947"; filename = "mlx-aarch64-apple-darwin20.whl"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
apk del cmake # Need CMake >= 3.30 for BLA_VENDOR=libblastrampoline

cd $WORKSPACE/srcdir/mlx

for patch in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 $patch
done

CMAKE_EXTRA_OPTIONS=()
if [[ "$target" == x86_64-apple-darwin* ]]; then
    CMAKE_EXTRA_OPTIONS+=(
        "-DCMAKE_CXX_FLAGS=-Wno-psabi -Wno-elaborated-enum-base" # Disabled psabi warnings, due to a lot being produced for mlx/backend/cpu/simd/accelerate_simd.h, and errors for CF_ENUM in the headers of the macOS 14 SDK
        -DMLX_ENABLE_X64_MAC=ON
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
    export TMPDIR=${WORKSPACE}/tmpdir # nvcc exhausts /tmp
    mkdir -pv ${TMPDIR}

    CMAKE_EXTRA_OPTIONS+=(
        -DMLX_BUILD_CUDA=ON
        -DCMAKE_RELEASE_POSTFIX=_cuda # A SONAME of its own, so that libmlx_cuda can be loaded next to libmlx
        -DMLX_CUDA_ARCHITECTURES=$cuda_archs # Set per platform in MLX_CUDA/build_tarballs.jl
        -DCMAKE_CUDA_COMPILER=${prefix}/cuda/bin/nvcc
        -DCMAKE_CUDA_FLAGS=-L${prefix}/cuda/lib
        -DCUDAToolkit_ROOT=${prefix}/cuda
        -DCUDNN_INCLUDE_PATH=${includedir}
        -DCUDNN_LIBRARY_PATH=${libdir}
    )
fi

if [[ $bb_full_target == *cuda* && $target == aarch64-* ]]; then
    export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
    export NVCC_PREPEND_FLAGS="-ccbin=${CXX}"
    rm -rfv ${prefix}/cuda/bin ${prefix}/cuda/nvvm/bin ${prefix}/cuda/nvvm/lib64
    cp -a ${WORKSPACE}/srcdir/cuda_nvcc-linux-x86_64-*-archive/bin ${prefix}/cuda/bin
    cp -a ${WORKSPACE}/srcdir/*-linux-x86_64-*-archive/nvvm/{bin,lib64} ${prefix}/cuda/nvvm/
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
        "${CMAKE_EXTRA_OPTIONS[@]}"
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

if [[ $bb_full_target == *cuda* && $target == aarch64-* ]]; then
    rm -rfv ${prefix}/cuda
fi
"""

# MLX uses Accelerate's new LAPACK interface, which needs macOS 13.3; 14.0 is the oldest available SDK that has it
sources, script = require_macos_sdk("14.0", sources, script; deployment_target="13.3")

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
    Dependency("OpenBLAS32_jll"; compat="0.3.28", platforms = openblas_platforms), # v0.3.28: v0.3.24–v0.3.27 have no aarch64-unknown-freebsd build
    Dependency("OpenMPI_jll"; compat="4.1.8, 5"), # OpenMPI 5 is ABI compatible with OpenMPI 4
    HostBuildDependency(PackageSpec(name="CMake_jll")), # Need CMake >= 3.30 for BLA_VENDOR=libblastrampoline
]

julia_compat="1.9"

preferred_gcc_version = v"11" # v11: C++20, with `__builtin_cpu_supports("f16c")`, required
