# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/facebookresearch/faiss.git", "189a9d4461233de798c2eb17fb6d354ceda542e6"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

# Bash recipe for building across all platforms
script = raw"""
# Needs CMake >= 3.23.1 provided via HostBuildDependency
apk del cmake

cd faiss

atomic_patch -p1 ../patches/faiss-mingw32-cmake.patch
atomic_patch -p1 ../patches/faiss-mingw32-InvertedListsIOHook.patch
atomic_patch -p1 ../patches/faiss-mingw32.patch
atomic_patch -p1 ../patches/gpu-shared_library.patch

cmake_extra_args=()

cuda_version=$(echo $bb_full_target | sed -E 's/.*-cuda\+([^-]+).*/\1/')
if [[ $bb_full_target == *cuda* ]]; then
    if [[ $cuda_version == "11.8" ]]; then
        cuda_archs=90
        #"60-real;61-real;62-real;70-real;72-real;75-real;80;86-real;87-real;89-real;90"
    elif [[ $cuda_version == "12.1" ]]; then
        cuda_archs="70-real;72-real;75-real;80;86-real;87-real;89-real;90"
    elif [[ $cuda_version == "12.4" ]]; then
        cuda_archs="70-real;72-real;75-real;80;86-real;87-real;89-real;90"
    else
        false # Fail for unexpected CUDA version
    fi

    # CUDA compilation can run out of storage
    mkdir $WORKSPACE/tmpdir
    export TMPDIR=$WORKSPACE/tmpdir

    export CUDA_PATH=$prefix/cuda
    ln -s $prefix/cuda/lib $prefix/cuda/lib64
    cmake_extra_args+=(
        -DFAISS_ENABLE_GPU=ON
        -DCUDAToolkit_ROOT=$CUDA_PATH
        -DCMAKE_CUDA_ARCHITECTURES=$cuda_archs
    )
fi

if $USE_CCACHE; then
    export CMAKE_CUDA_COMPILER_LAUNCHER=ccache
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

cmake -B build \
    -DBLA_VENDOR=libblastrampoline \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DFAISS_ENABLE_C_API=ON \
    -DFAISS_ENABLE_GPU=OFF \
    -DFAISS_ENABLE_MKL=OFF \
    -DFAISS_ENABLE_PYTHON=OFF \
    ${cmake_extra_args[@]}
cmake --build build --parallel ${nproc}
cmake --install build

install -Dvm 755 build/c_api/libfaiss_c.$dlext $libdir/libfaiss_c.$dlext

if [[ $bb_full_target == *cuda* ]]; then
    unlink $prefix/cuda/lib64
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = Product[
    FileProduct("include/faiss/Index.h", :faiss_index_h),
    FileProduct("include/faiss/c_api/faiss_c.h", :faiss_c_api_faiss_c_h),
    LibraryProduct(["libfaiss", "faiss"], :libfaiss),
    LibraryProduct(["libfaiss_c", "faiss_c"], :libfaiss_c),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
     # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency("libblastrampoline_jll"; compat="5.4"),
    HostBuildDependency(PackageSpec("CMake_jll", v"3.30.2")),
]
