# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/facebookresearch/faiss.git", "d243e628880676332263347817b3fe7f474b8b5b"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

# Bash recipe for building across all platforms
script = raw"""
# Needs CMake >= 3.23.1 provided via HostBuildDependency
apk del cmake

cd faiss

atomic_patch -p1 ../patches/faiss-cmake-mkl-optional.patch
atomic_patch -p1 ../patches/faiss-mingw32-cmake.patch
atomic_patch -p1 ../patches/faiss-mingw32-InvertedListsIOHook.patch
atomic_patch -p1 ../patches/faiss-mingw32.patch

cmake_extra_args=()

libblastrampoline_target=$(echo $bb_full_target | cut -d- -f 1-3)
if [[ "$libblastrampoline_target" != armv6l-linux-* &&
      "$bb_full_target" != i686-linux-gnu-cxx11 ]]; then
    if [[ "$target" == *-freebsd* ]]; then
        libblastrampoline_target=$rust_target
    fi
    cmake_extra_args+=(
        "-DBLAS_INCLUDE_DIRS=$includedir/libblastrampoline/LP64/$libblastrampoline_target"
        "-DBLAS_LIBRARIES=$libdir/libblastrampoline.$dlext"
        "-DLAPACK_INCLUDE_DIRS=$includedir/libblastrampoline/LP64/$libblastrampoline_target"
    )
fi

if [[ $bb_full_target == *cuda* ]]; then
    cuda_version=${bb_full_target##*-cuda+}
    if [[ $cuda_version == "11.8" ]]; then
        cuda_archs="60-real;61-real;62-real;70-real;72-real;75-real;80;86-real;87-real;89-real;90"
    elif [[ $cuda_version == "12.1" ]]; then
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

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DFAISS_ENABLE_GPU=OFF \
    -DFAISS_ENABLE_MKL=OFF \
    -DFAISS_ENABLE_PYTHON=OFF \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DFAISS_ENABLE_C_API=ON \
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

openblas_platforms = filter(p ->
    arch(p) == "armv6l" ||
    p == Platform("i686", "Linux"; libc = "glibc", cxxstring_abi = "cxx11") ||
    Sys.isfreebsd(p) && arch(p) == "aarch64",
    platforms
)
libblastrampoline_platforms = filter(p -> p ∉ openblas_platforms, platforms)

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
    Dependency("libblastrampoline_jll"; compat="5.4", platforms = libblastrampoline_platforms),
    Dependency("OpenBLAS32_jll"; platforms = openblas_platforms),
    HostBuildDependency(PackageSpec("CMake_jll", v"3.28.1")),
]
