version = v"1.8.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/facebookresearch/faiss.git", "22f2292be4aa98559797e1dd6e45f12386b06099"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

# Bash recipe for building across all platforms
script = raw"""
# Needs CMake >= 3.23.1 provided via HostBuildDependency
apk del cmake

cd faiss

atomic_patch -p1 ../patches/faiss-mingw32.patch

cmake_extra_args=()

if [[ $bb_full_target == *cuda* ]]; then
    export CUDACXX=$prefix/cuda/bin/nvcc
    cmake_extra_args+=(
        -DFAISS_ENABLE_GPU=ON
        -DCUDAToolkit_ROOT=$prefix/cuda
        -DCMAKE_CUDA_ARCHITECTURES="60"
    )
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DFAISS_ENABLE_GPU=OFF \
    -DFAISS_ENABLE_PYTHON=OFF \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DFAISS_ENABLE_C_API=ON \
    ${cmake_extra_args[@]}
cmake --build build --parallel ${nproc}
cmake --install build

install -Dvm 755 build/c_api/libfaiss_c.$dlext $libdir/libfaiss_c.$dlext
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

mkl_platforms = Platform[
    Platform("x86_64", "Linux"),
    Platform("i686", "Linux"),
    Platform("x86_64", "MacOS"),
    Platform("x86_64", "Windows"),
]

openblas_platforms = filter(p -> p ∉ mkl_platforms, platforms)

platforms = expand_cxxstring_abis(platforms)
mkl_platforms = expand_cxxstring_abis(mkl_platforms)
openblas_platforms = expand_cxxstring_abis(openblas_platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libfaiss", "faiss"], :libfaiss),
    LibraryProduct(["libfaiss_c", "faiss_c"], :libfaiss_c),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
     # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency("LAPACK_jll"; platforms = openblas_platforms),
    Dependency("MKL_jll"; platforms = mkl_platforms),
    BuildDependency("MKL_Headers_jll"; platforms = mkl_platforms),
    Dependency("OpenBLAS32_jll"; platforms = openblas_platforms),
    HostBuildDependency(PackageSpec("CMake_jll", v"3.28.1")),
]
