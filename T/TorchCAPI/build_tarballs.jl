using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "..", "fancy_toys.jl"))
include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "TorchCAPI"
version = v"1.10.2"

sources = [
    GitSource("https://github.com/FluxML/Torch.jl.git", "d1711d716c4993ca25e975aad5f7a638cfa7d7c2"),
]

script = raw"""
cmake_extra_args=""
if [[ $bb_full_target == *cuda* ]]; then
    cmake_extra_args+="\
        -DUSE_CUDA=ON \
        -DCUDA_TOOLKIT_ROOT_DIR=$prefix/cuda \
        -DCUDA_CUDART_LIBRARY=$libdir/libcudart.$dlext \
        -DCUDA_cublas_LIBRARY=$libdir/libcublas.$dlext \
        -DCUDA_cufft_LIBRARY=$libdir/libcufft.$dlext \
        -DCUDA_curand_LIBRARY=$libdir/libcurand.$dlext"
else
    cmake_extra_args+="\
        -DUSE_CUDA=OFF"
fi

cd Torch.jl/deps/c_wrapper
configure() {
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
        $cmake_extra_args \
        -S . \
        -B build
}
configure || configure || configure
cmake --build build -- -j $nproc

install -Dvm 755 build/libtorch_c_api.$dlext $libdir/libtorch_c_api.$dlext
"""

platforms = CUDA.supported_platforms(min_version=v"10.2", max_version=v"11.4")

platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct(["libtorch_c_api", "torch_c_api"], :libtorch_c_api),
]

dependencies = [
    Dependency("Torch_jll"; compat = "$version"),
    Dependency("CUDNN_jll", v"8.2.4"; compat = "8"),
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform, static_sdk = true)

    build_tarballs(ARGS, name, version, sources, script, [platform], products, [dependencies; cuda_deps];
    preferred_gcc_version = v"8",
    julia_compat = "1.6",
    augment_platform_block=CUDA.augment,
    lazy_artifacts=true)
end
