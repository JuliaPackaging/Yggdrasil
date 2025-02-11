using BinaryBuilder, Pkg
using BinaryBuilderBase: get_addable_spec

include(joinpath(@__DIR__, "..", "..", "fancy_toys.jl"))
include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "Torch"
version = v"1.10.2"

sources = [
    GitSource("https://github.com/pytorch/pytorch.git", "71f889c7d265b9636b93ede9d651c0a9c4bee191"),
    FileSource("https://micromamba.snakepit.net/api/micromamba/linux-64/0.21.1", "c907423887b43bec4e8b24f17471262c8087b7095683f41dcef4a4e24e9a3bbd"; filename = "micromamba.tar.bz2"),
    DirectorySource("./bundled"),
]

script = raw"""
cat > /opt/bin/$bb_full_target/xcrun << EOF
#!/bin/bash
if [[ "\${@}" == *"--show-sdk-path"* ]]; then
   echo /opt/$target/$target/sys-root
elif [[ "\${@}" == *"--show-sdk-version"* ]]; then
   grep -A1 '<key>Version</key>' /opt/$target/$target/sys-root/SDKSettings.plist \
   | tail -n1 \
   | sed -E -e 's/\s*<string>([^<]+)<\/string>\s*/\1/'
else
   exec "\${@}"
fi
EOF
chmod +x /opt/bin/$bb_full_target/xcrun

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

cuda_version=${bb_full_target##*-cuda+}
if [[ $bb_full_target == *cuda* ]] && [[ $cuda_version != none ]]; then
    export CUDA_PATH="$prefix/cuda"
    mkdir $WORKSPACE/tmpdir
    export TMPDIR=$WORKSPACE/tmpdir
    cmake_extra_args+="\
        -DUSE_CUDA=ON \
        -DUSE_CUDNN=ON \
        -DUSE_MAGMA=ON \
        -DCUDA_TOOLKIT_ROOT_DIR=$CUDA_PATH \
        -DCUB_INCLUDE_DIR=$WORKSPACE/srcdir/pytorch/third_party/cub "
    cuda_version_major=`echo $cuda_version | cut -d . -f 1`
    cuda_version_minor=`echo $cuda_version | cut -d . -f 2`
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
if [[ $bb_full_target == *cuda* ]] && [[ $cuda_version != none ]]; then
    configure || configure
else
    configure
fi
cmake --build . -- -j $nproc
make install
install_license ../LICENSE
"""

platforms = supported_platforms()
filter!(p -> !(Sys.islinux(p) && libc(p) == "musl"), platforms) # musl fails due to conflicting declaration of C function ‘void __assert_fail(const char*, const char*, int, const char*) - between /opt/x86_64-linux-musl/x86_64-linux-musl/include/c++/8.1.0/cassert:44 and /opt/x86_64-linux-musl/x86_64-linux-musl/sys-root/usr/include/assert.h
filter!(!Sys.iswindows, platforms) # ONNX does not support cross-compiling for w64-mingw32 on linux
filter!(p -> arch(p) != "armv6l", platforms) # armv6l is not supported by XNNPACK
filter!(p -> arch(p) != "armv7l", platforms) # armv7l is not supported by XNNPACK
filter!(p -> arch(p) != "powerpc64le", platforms) # PowerPC64LE is not supported by XNNPACK
filter!(!Sys.isfreebsd, platforms) # Build fails: Clang v12 crashes compiling aten/src/ATen/native/cpu/MaxUnpoolKernel.cpp.

let cuda_platforms = CUDA.supported_platforms(min_version=v"10.2", max_version=v"11")
    filter!(p -> arch(p) != "aarch64", cuda_platforms) # Cmake toolchain breaks on aarch64
    push!(cuda_platforms, Platform("x86_64", "Linux"; cuda = "11.3"))

     # Tag non-CUDA platforms matching CUDA platforms with cuda="none"
    for platform in platforms
        if CUDA.is_supported(platform) && arch(platform) != "aarch64"
            platform["cuda"] = "none"
        end
    end
    append!(platforms, cuda_platforms)
end

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

platforms = expand_cxxstring_abis(platforms)
accelerate_platforms = expand_cxxstring_abis(accelerate_platforms)
mkl_platforms = expand_cxxstring_abis(mkl_platforms)
openblas_platforms = expand_cxxstring_abis(openblas_platforms)

products = [
    FileProduct("share/ATen/Declarations.yaml", :declarations_yaml),
    LibraryProduct(["libtorch", "torch"], :libtorch),
    LibraryProduct(["libtorch_cpu", "torch_cpu"], :libtorch_cpu),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("CPUInfo_jll"; compat = "0.0.20201217"),
    Dependency("Gloo_jll";  compat = "0.0.20210521", platforms = filter(p -> nbits(p) == 64, platforms)),
    Dependency("LAPACK_jll"; platforms = openblas_platforms),
    # Dependency("MKL_jll"; platforms = mkl_platforms), # MKL is avoided for all platforms
    # BuildDependency("MKL_Headers_jll"; platforms = mkl_platforms), # MKL is avoided for all platforms

    # libtorch, libtorch_cuda, and libtorch_global_deps all link with `libnvToolsExt`
    # maleadt: `libnvToolsExt is not shipped by CUDA anymore, so the best solution is definitely static linking. CUDA 10.2 shipped it, later it became a header-only library which we do compile into a dynamic one for use with NVTX.jl, but there's no guarantees that the library we build has the same symbols as the "old" libnvToolsExt shipped by CUDA 10.2
    RuntimeDependency("NVTX_jll"), # TODO: Replace RuntimeDependency with static linking.

    Dependency("OpenBLAS32_jll"; platforms = openblas_platforms),
    Dependency("PThreadPool_jll"; compat = "0.0.20210414"),
    Dependency("SLEEF_jll", v"3.5.2"; compat = "3"),
    # Dependency("TensorRT_jll"; platforms = cuda_platforms), # Building with TensorRT is not supported: https://github.com/pytorch/pytorch/issues/60228
    Dependency("XNNPACK_jll"; compat = "0.0.20210622"),
    Dependency(PackageSpec("protoc_jll", Base.UUID("c7845625-083e-5bbe-8504-b32d602b7110")); compat="~3.13.0"),
    HostBuildDependency(PackageSpec("protoc_jll", Base.UUID("c7845625-083e-5bbe-8504-b32d602b7110"), v"3.13.0")),
]

builds = []
for platform in platforms
    should_build_platform(platform) || continue
    additional_deps = BinaryBuilder.AbstractDependency[]
    if haskey(platform, "cuda") && platform["cuda"] != "none"
        if platform["cuda"] == "11.3"
            additional_deps = BinaryBuilder.AbstractDependency[
                BuildDependency(PackageSpec("CUDA_full_jll", v"11.3.1")),
                Dependency("CUDA_Runtime_jll", v"0.7.0"), # Using v"0.7.0" to get support for cuda = "11.3" - using Dependency rather than RuntimeDependency to be sure to pass audit
            ]
        else
            additional_deps = CUDA.required_dependencies(platform, static_sdk = true)
        end
        push!(additional_deps,
            Dependency(get_addable_spec("CUDNN_jll", v"8.2.4+0"); compat = "8"), # Using v"8.2.4+0" to get support for cuda = "11.3"
        )
    end
    push!(builds, (; platforms=[platform], dependencies=[dependencies; additional_deps]))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, sources, script,
                   build.platforms, products, build.dependencies;
        preferred_gcc_version = v"8",
        preferred_llvm_version = v"13",
        julia_compat = "1.6",
        augment_platform_block = CUDA.augment,
        lazy_artifacts = true)
end
