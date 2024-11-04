using BinaryBuilder, Pkg
using BinaryBuilderBase: get_addable_spec

include(joinpath(@__DIR__, "..", "..", "fancy_toys.jl"))
include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "TorchCAPI"
version = v"0.2.0"

torch_version = v"1.10.2"

sources = [
    GitSource("https://github.com/FluxML/Torch.jl.git", "d1711d716c4993ca25e975aad5f7a638cfa7d7c2"),
    ArchiveSource("https://github.com/JuliaBinaryWrappers/CUDA_full_jll.jl/releases/download/CUDA_full-v11.3.1%2B1/CUDA_full.v11.3.1.x86_64-linux-gnu.tar.gz", "9ae00d36d39b04e8e99ace63641254c93a931dcf4ac24c8eddcdfd4625ab57d6"; unpack_target = "CUDA_full.v11.3"),
]

script = raw"""
cmake_extra_args=""
if [[ $bb_full_target == *cuda* ]]; then
    # CMake toolchain looks for compiler in CUDA_PATH/bin/nvcc
    if [[ $bb_full_target == *cuda+10* ]]; then
        export CUDA_PATH="$prefix/cuda"
    elif [[ $bb_full_target == *cuda+11.3* ]]; then
        export CUDA_PATH="/workspace/srcdir/CUDA_full.v11.3/cuda"
        export CUDARTLIB=cudart
        export cmake_extra_args="\
            -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
            -DCMAKE_CUDA_COMPILER_ID_RUN=1"
    fi
    cmake_extra_args+="\
        -DUSE_CUDA=ON \
        -DCUDA_TOOLKIT_ROOT_DIR=$CUDA_PATH"
else
    cmake_extra_args+="\
        -DUSE_CUDA=OFF"
fi

cd Torch.jl
install_license LICENSE

cd deps/c_wrapper
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

platforms = CUDA.supported_platforms(min_version=v"10.2", max_version=v"11")
filter!(p -> arch(p) != "aarch64", platforms) # Cmake toolchain breaks on aarch64
push!(platforms, Platform("x86_64", "Linux"; cuda = "11.3"))

platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct(["libtorch_c_api", "torch_c_api"], :libtorch_c_api),
]

dependencies = [
    Dependency("Torch_jll"; compat = "$torch_version"),
    Dependency(get_addable_spec("CUDNN_jll", v"8.2.4+0"); compat = "8"), # Using v"8.2.4+0" to get support for cuda = "11.3"
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    if platform["cuda"] == "11.3"
        cuda_deps = BinaryBuilder.AbstractDependency[
            Dependency("CUDA_Runtime_jll", v"0.7.0"), # Using v"0.7.0" to get support for cuda = "11.3" - using Dependency rather RuntimeDependency to be sure to pass audit
        ]
    else
        cuda_deps = CUDA.required_dependencies(platform, static_sdk = true)
    end

    build_tarballs(ARGS, name, version, sources, script, [platform], products, [dependencies; cuda_deps];
    preferred_gcc_version = v"8",
    julia_compat = "1.6",
    augment_platform_block=CUDA.augment,
    lazy_artifacts=true)
end
