using BinaryBuilder, Pkg
using BinaryBuilderBase: get_addable_spec

include(joinpath(@__DIR__, "..", "..", "fancy_toys.jl"))
include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "TorchCAPI"
version = v"0.2.0"

torch_version = v"1.10.2"

sources = [
    GitSource("https://github.com/FluxML/Torch.jl.git", "d1711d716c4993ca25e975aad5f7a638cfa7d7c2"),
]

script = raw"""
cmake_extra_args=""
if [[ $bb_full_target == *cuda* ]]; then
    # CMake toolchain looks for compiler in CUDA_PATH/bin/nvcc
    export CUDA_PATH="$prefix/cuda"
    if [[ $bb_full_target == *cuda+11.3* ]]; then
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

if [[ $bb_full_target == aarch64-linux-gnu-*-cxx03 ]]; then # Somehow CMake ends up adding '-D_GLIBCXX_USE_CXX11_ABI=' to CXX_FLAGS
    sed -i 's/ -D_GLIBCXX_USE_CXX11_ABI= / -D_GLIBCXX_USE_CXX11_ABI=0 /' build/CMakeFiles/torch_c_api.dir/flags.make
fi

cmake --build build -- -j $nproc

install -Dvm 755 build/libtorch_c_api.$dlext $libdir/libtorch_c_api.$dlext

for header_path in $(ls -1 *.h | grep -v cpp); do
    install -Dvm 644 $header_path $includedir/torch_c_api/$header_path
done
"""

platforms = supported_platforms()
# Exclude platforms not available for Torch_jll
filter!(p -> !(Sys.islinux(p) && libc(p) == "musl"), platforms)
filter!(!Sys.iswindows, platforms)
filter!(p -> arch(p) != "armv6l", platforms)
filter!(p -> arch(p) != "armv7l", platforms)
filter!(p -> arch(p) != "powerpc64le", platforms)
filter!(!Sys.isfreebsd, platforms)

cuda_platforms = CUDA.supported_platforms(min_version=v"10.2", max_version=v"11")
filter!(p -> arch(p) != "aarch64", cuda_platforms) # Cmake toolchain breaks on aarch64
push!(cuda_platforms, Platform("x86_64", "Linux"; cuda = "11.3"))

filter!(p -> !(arch(p) == "x86_64" && Sys.islinux(p)), platforms) # Exclude non-CUDA x86_64 Linux platforms as CMake tries to find CUDA on these platforms (as well)

append!(platforms, cuda_platforms)

platforms = expand_cxxstring_abis(platforms)
cuda_platforms = expand_cxxstring_abis(cuda_platforms)

products = [
    LibraryProduct(["libtorch_c_api", "torch_c_api"], :libtorch_c_api),
]

dependencies = [
    Dependency("Torch_jll"; compat = "$torch_version"),
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    additional_deps = BinaryBuilder.AbstractDependency[]
    if haskey(platform, "cuda")
        if platform["cuda"] == "11.3"
            additional_deps = BinaryBuilder.AbstractDependency[
                BuildDependency(PackageSpec("CUDA_full_jll", v"11.3.1")),
                Dependency("CUDA_Runtime_jll", v"0.7.0"), # Using v"0.7.0" to get support for cuda = "11.3" - using Dependency rather RuntimeDependency to be sure to pass audit
            ]
        else
            additional_deps = CUDA.required_dependencies(platform, static_sdk = true)
        end
        push!(additional_deps,
            Dependency(get_addable_spec("CUDNN_jll", v"8.2.4+0"); compat = "8"), # Using v"8.2.4+0" to get support for cuda = "11.3"
        )
    end

    build_tarballs(ARGS, name, version, sources, script, [platform], products, [dependencies; additional_deps];
        preferred_gcc_version = v"8",
        julia_compat = "1.6",
        augment_platform_block=CUDA.augment,
        lazy_artifacts=true)
end
