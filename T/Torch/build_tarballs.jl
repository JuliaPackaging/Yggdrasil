# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "Torch"
version = v"1.10.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pytorch/pytorch.git", "71f889c7d265b9636b93ede9d651c0a9c4bee191"),
    FileSource("https://micromamba.snakepit.net/api/micromamba/linux-64/0.21.1", "c907423887b43bec4e8b24f17471262c8087b7095683f41dcef4a4e24e9a3bbd"; filename = "micromamba.tar.bz2"),
    ArchiveSource("https://github.com/JuliaBinaryWrappers/CUDA_full_jll.jl/releases/download/CUDA_full-v10.2.89%2B5/CUDA_full.v10.2.89.x86_64-linux-gnu.tar.gz", "60e6f614db3b66d955b7e6aa02406765e874ff475c69e2b4a04eb95ba65e4f3b"; unpack_target = "CUDA_full.v10.2"),
    ArchiveSource("https://github.com/JuliaBinaryWrappers/CUDA_full_jll.jl/releases/download/CUDA_full-v11.3.1%2B1/CUDA_full.v11.3.1.x86_64-linux-gnu.tar.gz", "9ae00d36d39b04e8e99ace63641254c93a931dcf4ac24c8eddcdfd4625ab57d6"; unpack_target = "CUDA_full.v11.3"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

mkdir micromamba
cd micromamba
tar xfj ../micromamba.tar.bz2
export PATH=$PATH:$WORKSPACE/srcdir/micromamba/bin
./bin/micromamba shell init -s bash -p ~/micromamba
source ~/.bashrc
micromamba activate
micromamba install -y python=3.9 pyyaml typing_extensions -c conda-forge

cd $WORKSPACE/srcdir/pytorch

atomic_patch -p1 ../patches/pytorch-aten-qnnpack-cmake-windows.patch

cmake_extra_args=""
include_paths=""

if [[ $bb_full_target == *cxx11* ]]; then
    cmake_extra_args+="-DGLIBCXX_USE_CXX11_ABI=1 "
fi

# MKL is avoided for all platforms are excluded due to https://github.com/JuliaRegistries/General/pull/68946#issuecomment-1257308450
if [[ 0 -eq 1
    # || $target == i686-linux-gnu*
    # || $target == x86_64-linux-gnu*
    # || $target == x86_64-apple-darwin*
]]; then
    cmake_extra_args+="-DBLAS=MKL "
elif [[ $target == x86_64-apple-darwin*
    || $target == aarch64-apple-darwin*
]]; then
    cmake_extra_args+="-DBLAS=vecLib "
else
    cmake_extra_args+="-DBLAS=OpenBLAS "
fi

if [[ $target == x86_64* ]]; then # Restricting PYTORCH_QNNPACK to x86_64: Adapted from https://salsa.debian.org/deeplearning-team/pytorch/-/blob/master/debian/rules
    cmake_extra_args+="-DUSE_PYTORCH_QNNPACK=ON "
else
    cmake_extra_args+="-DUSE_PYTORCH_QNNPACK=OFF "
fi

if [[ $target == aarch64-linux-gnu* # Disabled use of breakpad on aarch64-linux-gnu: Fails to build embedded breakpad library.
    || $target == *-w64-mingw32* # Disabling breakpad enables configure on Windows - in combination with pytorch-aten-qnnpack-cmake-windows.patch
    || $target == *-freebsd*
]]; then
    cmake_extra_args+="-DUSE_BREAKPAD=OFF "
else
    cmake_extra_args+="-DUSE_BREAKPAD=ON "
fi

if [[ $target == *-linux-musl* # Disabled use of TensorPipe on linux-musl: Fails to build embedded TensorPipe library.
    || $target == *-w64-mingw32* # TensorPipe cannot be used on Windows
]]; then
    cmake_extra_args+="-DUSE_TENSORPIPE=OFF "
else
    cmake_extra_args+="-DUSE_TENSORPIPE=ON "
fi

if [[ $target == *-w64-* || $target == *-freebsd* ]]; then
    cmake_extra_args+="-DUSE_KINETO=OFF "
fi

# Gloo is only available for 64-bit x86_64 or aarch64 - and cmake currently cannot find Gloo on *-linux-gnu
if [[ $target != arm-* && $target == *-linux-musl* ]]; then
    cmake_extra_args+="-DUSE_SYSTEM_GLOO=ON "
fi

if [[ $target == aarch64-* # A compiler with AVX512 support is required for FBGEM
    || $target == arm-* # A compiler with AVX512 support is required for FBGEM
    || $target == i686-* # x64 operating system is required for FBGEMM
    || $target == x86_64-w64-mingw32*
]]; then
    cmake_extra_args+="-DUSE_FBGEMM=OFF -DUSE_FAKELOWP=OFF "
fi

if [[ $target == x86_64-apple-darwin* # Fails to compile: /workspace/srcdir/pytorch/third_party/ideep/mkl-dnn/src/cpu/x64/jit_avx512_core_amx_conv_kernel.cpp:483:43: error: use of undeclared identifier 'noU';
    || $target == *-w64-mingw32*
    || $target == *-linux-musl* ]]; then
    cmake_extra_args+="-DUSE_MKLDNN=OFF "
fi

if [[ $bb_full_target == *cuda* ]]; then
    cuda_version=`echo $bb_full_target | sed -E -e 's/.*cuda\+([0-9]+\.[0-9]+).*/\1/'`
    cuda_version_major=`echo $cuda_version | cut -d . -f 1`
    cuda_version_minor=`echo $cuda_version | cut -d . -f 2`
    cuda_full_path="$WORKSPACE/srcdir/CUDA_full.v$cuda_version/cuda"
    export PATH=$PATH:$cuda_full_path/bin
    export CUDACXX=$cuda_full_path/bin/nvcc
    export CUDAHOSTCXX=$CXX
    mkdir $WORKSPACE/tmpdir
    export TMPDIR=$WORKSPACE/tmpdir
    cmake_extra_args+="\
        -DUSE_CUDA=ON \
        -DUSE_CUDNN=ON \
        -DUSE_MAGMA=ON \
        -DCUDA_TOOLKIT_ROOT_DIR=$cuda_full_path \
        -DCUDA_CUDART_LIBRARY=$cuda_full_path/lib64/libcudart.$dlext \
        -DCMAKE_CUDA_FLAGS='-cudart shared' \
        -DCUDA_cublas_LIBRARY=$cuda_full_path/lib64/libcublas.$dlext \
        -DCUDA_cufft_LIBRARY=$cuda_full_path/lib64/libcufft.$dlext \
        -DCUDA_curand_LIBRARY=$cuda_full_path/lib64/libcurand.$dlext \
        -DCUDA_cusolver_LIBRARY=$cuda_full_path/lib64/libcusolver.$dlext \
        -DCUDA_cusparse_LIBRARY=$cuda_full_path/lib64/libcusparse.$dlext \
        -DCUDA_TOOLKIT_INCLUDE=$includedir;$cuda_full_path/include \
        -DCUB_INCLUDE_DIR=$WORKSPACE/srcdir/pytorch/third_party/cub "
    include_paths+=":$cuda_full_path/include"
    micromamba install -y magma-cuda${cuda_version_major}${cuda_version_minor} -c pytorch
    git submodule update --init \
        third_party/cub \
        third_party/cudnn_frontend
else
    cmake_extra_args+="-DUSE_CUDA=OFF -DUSE_MAGMA=OFF "
fi

git submodule update --init \
    third_party/FP16 \
    third_party/FXdiv \
    third_party/eigen \
    third_party/fbgemm \
    third_party/fmt \
    third_party/foxi \
    third_party/gloo \
    third_party/kineto \
    third_party/onnx \
    third_party/psimd \
    third_party/tensorpipe
git submodule update --init --recursive \
    third_party/breakpad \
    third_party/ideep
cd third_party/fbgemm && git submodule update --init third_party/asmjit && cd ../..
cd third_party/tensorpipe && git submodule update --init third_party/libnop third_party/libuv && cd ../..
mkdir build
cd build
configure() {
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_INCLUDE_PATH=$include_paths \
        -DBUILD_CUSTOM_PROTOBUF=OFF \
        -DBUILD_PYTHON=OFF \
        -DPYTHON_EXECUTABLE=`which python3` \
        -DBUILD_SHARED_LIBS=ON \
        -DHAVE_SOVERSION=ON \
        -DUSE_METAL=OFF \
        -DUSE_MPI=OFF \
        -DUSE_NCCL=OFF \
        -DUSE_NNPACK=OFF \
        -DUSE_NUMA=OFF \
        -DUSE_NUMPY=OFF \
        -DUSE_QNNPACK=OFF \
        -DUSE_SYSTEM_CPUINFO=ON \
        -DUSE_SYSTEM_PTHREADPOOL=ON \
        -DUSE_SYSTEM_SLEEF=ON \
        -DUSE_SYSTEM_XNNPACK=ON \
        -DPROTOBUF_PROTOC_EXECUTABLE=$host_bindir/protoc \
        -DCAFFE2_CUSTOM_PROTOC_EXECUTABLE=$host_bindir/protoc \
        -Wno-dev \
        $cmake_extra_args \
        ..
}
if [[ $bb_full_target != *cuda* ]]; then
    configure
else
    configure
    configure || configure
fi
cmake --build . -- -j $nproc
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !(Sys.islinux(p) && libc(p) == "musl"), platforms) # musl fails due to conflicting declaration of C function ‘void __assert_fail(const char*, const char*, int, const char*) - between /opt/x86_64-linux-musl/x86_64-linux-musl/include/c++/8.1.0/cassert:44 and /opt/x86_64-linux-musl/x86_64-linux-musl/sys-root/usr/include/assert.h
filter!(!Sys.iswindows, platforms) # ONNX does not support cross-compiling for w64-mingw32 on linux
filter!(p -> arch(p) != "armv6l", platforms) # armv6l is not supported by XNNPACK
filter!(p -> arch(p) != "armv7l", platforms) # armv7l is not supported by XNNPACK
filter!(p -> arch(p) != "powerpc64le", platforms) # PowerPC64LE is not supported by XNNPACK
filter!(!Sys.isfreebsd, platforms) # Build fails: Clang v12 crashes compiling aten/src/ATen/native/cpu/MaxUnpoolKernel.cpp.

accelerate_platforms = [
    Platform("aarch64", "macos"),
    Platform("x86_64", "macos"),
]

# MKL is avoided for all platforms due to https://github.com/JuliaRegistries/General/pull/68946#issuecomment-1257308450
mkl_platforms = Platform[
    # Platform("x86_64", "Linux"),
    # Platform("i686", "Linux"),
    # Platform("x86_64", "MacOS"),
    # Platform("x86_64", "Windows"),
]

openblas_platforms = filter(p -> p ∉ union(mkl_platforms, accelerate_platforms), platforms)

cuda_platforms = [
    Platform("x86_64", "Linux"; cuda = "10.2"),
    Platform("x86_64", "Linux"; cuda = "11.3"),
]
for p in cuda_platforms
    push!(platforms, p)
end

platforms = expand_cxxstring_abis(platforms)
accelerate_platforms = expand_cxxstring_abis(accelerate_platforms)
mkl_platforms = expand_cxxstring_abis(mkl_platforms)
openblas_platforms = expand_cxxstring_abis(openblas_platforms)
cuda_platforms = expand_cxxstring_abis(cuda_platforms)

# The products that we will ensure are always built
products = [
    FileProduct("share/ATen/Declarations.yaml", :declarations_yaml),
    LibraryProduct(["libtorch", "torch"], :libtorch),
    LibraryProduct(["libtorch_cpu", "torch_cpu"], :libtorch_cpu),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("CPUInfo_jll"; compat = "0.0.20201217"),
    Dependency("CUDNN_jll", v"8.2.4"; compat = "8", platforms = cuda_platforms),
    Dependency("Gloo_jll";  compat = "0.0.20210521", platforms = filter(p -> nbits(p) == 64, platforms)),
    Dependency("LAPACK_jll"; platforms = openblas_platforms),
    # Dependency("MKL_jll"; platforms = mkl_platforms), # MKL is avoided for all platforms
    # BuildDependency("MKL_Headers_jll"; platforms = mkl_platforms), # MKL is avoided for all platforms
    Dependency("OpenBLAS32_jll"; platforms = openblas_platforms),
    Dependency("PThreadPool_jll"; compat = "0.0.20210414"),
    Dependency("SLEEF_jll", v"3.5.2"; compat = "3"),
    # Dependency("TensorRT_jll"; platforms = cuda_platforms), # Building with TensorRT is not supported: https://github.com/pytorch/pytorch/issues/60228
    Dependency("XNNPACK_jll"; compat = "0.0.20210622"),
    Dependency(PackageSpec("protoc_jll", Base.UUID("c7845625-083e-5bbe-8504-b32d602b7110")); compat="~3.13.0"),
    HostBuildDependency(PackageSpec("protoc_jll", Base.UUID("c7845625-083e-5bbe-8504-b32d602b7110"), v"3.13.0")),
    RuntimeDependency("CUDA_Runtime_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"8",
    julia_compat = "1.6",
    augment_platform_block = CUDA.augment)
