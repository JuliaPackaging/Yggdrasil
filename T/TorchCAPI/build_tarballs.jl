using BinaryBuilder, Pkg

name = "TorchCAPI"
version = v"1.10.2"

sources = [
    GitSource("https://github.com/IHPSystems/Torch.jl.git", "b27df7dd4ae9b20e075ea239e2bd0d6c04b9827f"),
    ArchiveSource("https://github.com/JuliaBinaryWrappers/CUDA_full_jll.jl/releases/download/CUDA_full-v11.3.1%2B1/CUDA_full.v11.3.1.x86_64-linux-gnu.tar.gz", "9ae00d36d39b04e8e99ace63641254c93a931dcf4ac24c8eddcdfd4625ab57d6"; unpack_target = "CUDA_full.v11.3"),
]

script = raw"""
cmake_extra_args=""
if [[ $bb_full_target == *cuda* ]]; then
    cmake_extra_args+="\
        -DCUDA_TOOLKIT_ROOT_DIR=/workspace/srcdir/CUDA_full.v11.3/cuda \
        -DCUDA_CUDART_LIBRARY=$libdir/libcudart.$dlext \
        -DCUDA_cublas_LIBRARY=$libdir/libcublas.$dlext \
        -DCUDA_cufft_LIBRARY=$libdir/libcufft.$dlext \
        -DCUDA_curand_LIBRARY=$libdir/libcurand.$dlext "
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
make install
"""

platforms = supported_platforms()
filter!(p -> !(Sys.islinux(p) && libc(p) == "musl"), platforms)
filter!(!Sys.iswindows, platforms)
filter!(p -> arch(p) != "armv6l", platforms)
filter!(p -> arch(p) != "armv7l", platforms)
filter!(p -> arch(p) != "powerpc64le", platforms)
filter!(!Sys.isfreebsd, platforms)

cuda_platforms = [
    Platform("x86_64", "Linux"; cuda = "10.2"),
    Platform("x86_64", "Linux"; cuda = "11.3"),
]
for p in cuda_platforms
    push!(platforms, p)
end

platforms = expand_cxxstring_abis(platforms)
cuda_platforms = expand_cxxstring_abis(cuda_platforms)

products = [
    LibraryProduct(["libtch", "tch"], :libtch),
]

dependencies = [
    Dependency("Torch_jll"; compat = "$version"),
    Dependency("CUDNN_jll", v"8.2.4"; compat = "8", platforms = cuda_platforms),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"8",
    julia_compat = "1.6")
