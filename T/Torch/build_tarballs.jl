# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Torch"
version = v"1.10.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pytorch/pytorch.git", "71f889c7d265b9636b93ede9d651c0a9c4bee191"),
    FileSource("https://micromamba.snakepit.net/api/micromamba/linux-64/0.21.1", "c907423887b43bec4e8b24f17471262c8087b7095683f41dcef4a4e24e9a3bbd"; filename = "micromamba.tar.bz2")
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

if [[ $bb_full_target == *cxx11* ]]; then
    cmake_extra_args+="-DGLIBCXX_USE_CXX11_ABI=1 "
fi

if [[ $target == i686-linux-gnu*
    || $target == x86_64-linux-gnu*
    || $target == x86_64-apple-darwin*
]]; then
    cmake_extra_args+="-DBLAS=MKL "
elif [[ $target == aarch64-linux-gnu*
    || $bb_full_target == armv7l-linux-gnu*
    || $target == x86_64-linux-musl*
    || $target == x86_64-unknown-freebsd*
    || $target == aarch64-apple-darwin*
    || $target == i686-w64-mingw32*
    || $target == x86_64-w64-mingw32*
]]; then
    cmake_extra_args+="-DBLAS=BLIS "
elif [[ $bb_full_target == armv6l-linux-gnu* ]]; then
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
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_CUSTOM_PROTOBUF=OFF \
    -DBUILD_PYTHON=OFF \
    -DPYTHON_EXECUTABLE=`which python3` \
    -DBUILD_SHARED_LIBS=ON \
    -DHAVE_SOVERSION=ON \
    -DUSE_CUDA=OFF \
    -DUSE_MAGMA=OFF \
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

mkl_platforms = [
    Platform("x86_64", "Linux"),
    Platform("i686", "Linux"),
    Platform("x86_64", "MacOS"),
    Platform("x86_64", "Windows"),
]

blis_platforms = filter(p -> p ∉ mkl_platforms, [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("x86_64", "freebsd"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
])

openblas_platforms = filter(p -> p ∉ union(mkl_platforms, blis_platforms), platforms)

platforms = expand_cxxstring_abis(platforms)
mkl_platforms = expand_cxxstring_abis(mkl_platforms)
blis_platforms = expand_cxxstring_abis(blis_platforms)
openblas_platforms = expand_cxxstring_abis(openblas_platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libtorch", "torch"], :libtorch),
    LibraryProduct(["libtorch_cpu", "torch_cpu"], :libtorch_cpu),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("blis_jll"; platforms = blis_platforms),
    Dependency("CPUInfo_jll"; compat = "0.0.20201217"),
    Dependency("Gloo_jll";  compat = "0.0.20210521", platforms = filter(p -> nbits(p) == 64, platforms)),
    Dependency("LAPACK_jll"; platforms = openblas_platforms),
    Dependency("MKL_jll"; platforms = mkl_platforms),
    BuildDependency("MKL_Headers_jll"; platforms = mkl_platforms),
    Dependency("OpenBLAS_jll"; platforms = openblas_platforms),
    Dependency("PThreadPool_jll"; compat = "0.0.20210414"),
    Dependency("SLEEF_jll", v"3.5.2"; compat = "3"),
    Dependency("XNNPACK_jll"; compat = "0.0.20210622"),
    BuildDependency(PackageSpec("protoc_jll", Base.UUID("c7845625-083e-5bbe-8504-b32d602b7110"), v"3.13.0")),
    HostBuildDependency(PackageSpec("protoc_jll", Base.UUID("c7845625-083e-5bbe-8504-b32d602b7110"), v"3.13.0")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"8",
    julia_compat = "1.6")
