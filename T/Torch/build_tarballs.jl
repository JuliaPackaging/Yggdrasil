using BinaryBuilder, Pkg
using BinaryBuilderBase: get_addable_spec

include(joinpath(@__DIR__, "..", "..", "fancy_toys.jl"))
include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "Torch"
version = v"1.11.0"

sources = [
    GitSource("https://github.com/pytorch/pytorch.git", "bc2c6edaf163b1a1330e37a6e34caf8c553e4755"),
    FileSource("https://micromamba.snakepit.net/api/micromamba/linux-64/0.21.1", "c907423887b43bec4e8b24f17471262c8087b7095683f41dcef4a4e24e9a3bbd"; filename = "micromamba.tar.bz2"),
    DirectorySource("./bundled"),
]

script = raw"""
apk del cmake # Need CMake >= 3.30 for BLA_VENDOR=libblastrampoline

export SDKROOT=/opt/$target/$target/sys-root

cat > /opt/bin/$bb_full_target/xcrun << EOF
#!/bin/sh

sdk_path="\$SDKROOT"

show_sdk_path() {
    echo "\$1"
}

show_sdk_version() {
    plistutil -f xml -i "\$1"/SDKSettings.plist \\
    | grep -A1 '<key>Version</key>' \\
    | tail -n1 \\
    | sed -E -e 's/\\s*<string>([^<]+)<\\/string>\\s*/\\1/'
}

while [ \$# -gt 0 ]; do
    case "\$1" in
        --sdk)
            sdk_path="\$2"
            shift 2
            ;;
        --show-sdk-path)
            show_sdk_path "\$sdk_path"
            shift
            ;;
        --show-sdk-version)
            show_sdk_version "\$sdk_path"
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [ \$# -gt 0 ]; then
"\$@"
fi
EOF
chmod +x /opt/bin/$bb_full_target/xcrun

cd $WORKSPACE/srcdir

mkdir -p micromamba
cd micromamba
tar xfj ../micromamba.tar.bz2
export PATH=$PATH:$WORKSPACE/srcdir/micromamba/bin
./bin/micromamba shell init -s bash -p ~/micromamba
source ~/.bashrc
micromamba activate
micromamba install -y python=3.9 pyyaml typing_extensions -c conda-forge

cd $WORKSPACE/srcdir/pytorch

atomic_patch -p1 ../patches/pytorch-aten-qnnpack-cmake-windows.patch
atomic_patch -p1 ../patches/pytorch-cmake-blas-default.patch

cmake_extra_args=()
include_paths=()

if [[ "$bb_full_target" != armv6l-linux-* ]]; then
    # Remove custom FindBLAS, and FindLAPACK, cmake modules to let cmake find libblastrampoline
    rm -v cmake/Modules/Find{BLAS,LAPACK}.cmake
    cmake_extra_args+=(
        -DBLA_VENDOR=libblastrampoline
        -DBLAS=Default
    )
else
    cmake_extra_args+=(-DBLAS=OpenBLAS)
fi

# Only enable XNNPACK for supported architectures
if [[ $bb_full_target == armv6l-*
    || $bb_full_target == armv7l-* # XNNPACK for armv7l requires neon instructions
    || $target == powerpc64le-*
    || $target == riscv64-*
]]; then
    cmake_extra_args+=(-DUSE_XNNPACK=OFF)
else
    cmake_extra_args+=(
        -DUSE_XNNPACK=ON
        -DUSE_SYSTEM_XNNPACK=ON
    )
fi

# if [[ $target == x86_64* ]]; then # Restricting PYTORCH_QNNPACK to x86_64: Adapted from https://salsa.debian.org/deeplearning-team/pytorch/-/blob/master/debian/rules
    cmake_extra_args+=(-DUSE_PYTORCH_QNNPACK=ON)
# else
#     cmake_extra_args+=(-DUSE_PYTORCH_QNNPACK=OFF)
# fi

if [[ $target == aarch64-linux-gnu* # Fails to build embedded breakpad library
    || $target == powerpc64le-* # Fails to build embedded breakpad library
    || $target == *-w64-mingw32* # Disabling breakpad enables configure on Windows - in combination with pytorch-aten-qnnpack-cmake-windows.patch
    || $target == *-freebsd* # Fails to build embedded breakpad library
]]; then
    cmake_extra_args+=(-DUSE_BREAKPAD=OFF)
else
    cmake_extra_args+=(-DUSE_BREAKPAD=ON)
fi

if [[ $target == *-w64-mingw32* ]]; then # TensorPipe does not support Windows, and USE_DISTRIBUTED on Windows requires libuv 
    cmake_extra_args+=(-DUSE_DISTRIBUTED=OFF)
elif [[ $target == *-linux-musl* ]]; then # Fails to build embedded TensorPipe library.
    cmake_extra_args+=(-DUSE_TENSORPIPE=OFF)
else
    cmake_extra_args+=(-DUSE_TENSORPIPE=ON)
fi

if [[ $target == *-w64-mingw32-* # Fails to compile: third_party/kineto/libkineto/src/ThreadUtil.cpp:6:10: fatal error: sys/syscall.h: No such file or directory
    || $target == *-freebsd* # Fails to compile: third_party/kineto/libkineto/src/ThreadUtil.cpp:52:32: error: use of undeclared identifier 'SYS_gettid'
]]; then
    cmake_extra_args+=(-DUSE_KINETO=OFF)
fi

# Gloo is only available for 64-bit x86_64 or aarch64 - and cmake currently cannot find Gloo on *-linux-gnu
# if [[ $target != arm-* && $target == *-linux-musl* ]]; then
    cmake_extra_args+=(-DUSE_SYSTEM_GLOO=ON)
# fi

if [[ 0 -eq 1
    || $nbits != 64 # Quiets the CMake Warning: x64 operating system is required for FBGEMM
    || $target != x86_64-* # Quiets the CMake Warning: A compiler with AVX512 support is required for FBGEMM
    || $target == x86_64-apple-darwin* # Fails to compile: third_party/fbgemm/third_party/asmjit
    || $target == x86_64-unknown-freebsd* # Fails to compile: third_party/fbgemm/third_party/asmjit
    || $target == x86_64-w64-mingw32* # Fails to compile: third_party/fbgemm
]]; then
    cmake_extra_args+=(-DUSE_FBGEMM=OFF -DUSE_FAKELOWP=OFF)
fi

# if [[ $target == *-linux-musl* ]]; then
#     cmake_extra_args+=(-DUSE_MKLDNN=OFF)
# fi

cuda_version=${bb_full_target##*-cuda+}
if [[ $bb_full_target == *cuda* ]] && [[ $cuda_version != none ]]; then
    export CUDA_PATH="$prefix/cuda"
    mkdir $WORKSPACE/tmpdir
    export TMPDIR=$WORKSPACE/tmpdir
    cmake_extra_args+=(
        -DUSE_CUDA=ON
        -DUSE_CUDNN=ON
        -DUSE_MAGMA=ON
        -DCUDA_TOOLKIT_ROOT_DIR=$CUDA_PATH
    )
    cuda_version_major=`echo $cuda_version | cut -d . -f 1`
    cuda_version_minor=`echo $cuda_version | cut -d . -f 2`
    micromamba install -y magma-cuda${cuda_version_major}${cuda_version_minor} -c pytorch
    git submodule update --init third_party/cudnn_frontend

    if [[ $cuda_version_major == 10 ]]; then
        cmake_extra_args+=(-DCUB_INCLUDE_DIR=$WORKSPACE/srcdir/pytorch/third_party/cub)
        git submodule update --init third_party/cub
    fi
else
    cmake_extra_args+=(-DUSE_CUDA=OFF -DUSE_MAGMA=OFF)
fi

git submodule update --init --depth 1 \
    third_party/FP16 \
    third_party/FXdiv \
    third_party/eigen \
    third_party/fbgemm \
    third_party/flatbuffers \
    third_party/fmt \
    third_party/foxi \
    third_party/gloo \
    third_party/kineto \
    third_party/onnx \
    third_party/pocketfft \
    third_party/psimd \
    third_party/tensorpipe
git submodule update --init --depth 1 --recursive \
    third_party/breakpad \
    third_party/ideep
cd third_party/fbgemm && git submodule update --init --depth 1 third_party/asmjit && cd ../..
cd third_party/tensorpipe && git submodule update --init --depth 1 third_party/libnop third_party/libuv && cd ../..

configure() {
    cmake_generator=$([[ $target == *-w64-mingw32* ]] && echo "Unix Makefiles" || echo Ninja)
    cmake \
        -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_INCLUDE_PATH=$include_paths \
        -DBUILD_CUSTOM_PROTOBUF=OFF \
        -DBUILD_PYTHON=OFF \
        -DPYTHON_EXECUTABLE=$(which python3) \
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
        -DPROTOBUF_PROTOC_EXECUTABLE=$host_bindir/protoc \
        -DCAFFE2_CUSTOM_PROTOC_EXECUTABLE=$host_bindir/protoc \
        -G "$cmake_generator" \
        -Wno-dev \
        ${cmake_extra_args[@]}
}
if [[ $bb_full_target == *cuda* ]] && [[ $cuda_version != none ]]; then
    configure || configure
else
    configure
fi
cmake --build build --parallel $nproc
cmake --install build
install_license LICENSE
"""

platforms = supported_platforms()
filter!(p -> libc(p) != "musl", platforms)
filter!(p -> arch(p) != "powerpc64le", platforms) # Fails due to: aten/src/ATen/native/attention.cpp:145:46: error: use of deleted function ‘double& at::vec::CPU_CAPABILITY::Vectorized<double>::operator[](int)’
filter!(p -> arch(p) != "riscv64", platforms) # Artifacts are not available for dependencies for riscv64
filter!(p -> arch(p) != "aarch64" || !Sys.isfreebsd(p), platforms) # Artifacts are not available for dependencies for aarch64-unknown-freebsd
filter!(!Sys.iswindows, platforms) # ONNX does not support cross-compiling for w64-mingw32 on linux

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

# platforms = expand_cxxstring_abis(platforms)

openblas_platforms = filter(p -> arch(p) == "armv6l", platforms)
libblastrampoline_platforms = filter(p -> p ∉ openblas_platforms, platforms)

products = [
    FileProduct("share/ATen/Declarations.yaml", :declarations_yaml),
    LibraryProduct(["libtorch", "torch"], :libtorch),
    LibraryProduct(["libtorch_cpu", "torch_cpu"], :libtorch_cpu),
]

dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency("CompilerSupportLibraries_jll", platforms = filter(!Sys.isbsd, platforms)),
    Dependency("LLVMOpenMP_jll", platforms = filter(Sys.isbsd, platforms)),

    Dependency("CPUInfo_jll"; compat = "0.0.20201217"),
    Dependency("Gloo_jll";  compat = "0.0.20210521", platforms = filter(p -> nbits(p) == 64, platforms)),
    Dependency("libblastrampoline_jll"; compat="5.4", platforms = libblastrampoline_platforms),

    # libtorch, libtorch_cuda, and libtorch_global_deps all link with `libnvToolsExt`
    # maleadt: `libnvToolsExt is not shipped by CUDA anymore, so the best solution is definitely static linking. CUDA 10.2 shipped it, later it became a header-only library which we do compile into a dynamic one for use with NVTX.jl, but there's no guarantees that the library we build has the same symbols as the "old" libnvToolsExt shipped by CUDA 10.2
    RuntimeDependency("NVTX_jll"), # TODO: Replace RuntimeDependency with static linking.

    Dependency("OpenBLAS32_jll"; platforms = openblas_platforms),
    Dependency("PThreadPool_jll"; compat = "0.0.20210414"),
    Dependency("SLEEF_jll", v"3.5.2"; compat = "3"),
    Dependency("XNNPACK_jll"; compat = "0.0.20210622"),
    Dependency(PackageSpec("protoc_jll", Base.UUID("c7845625-083e-5bbe-8504-b32d602b7110")); compat="~3.13.0"),
    HostBuildDependency(PackageSpec("protoc_jll", Base.UUID("c7845625-083e-5bbe-8504-b32d602b7110"), v"3.13.0")),
    HostBuildDependency(PackageSpec(name="CMake_jll")), # Need CMake >= 3.30 for BLA_VENDOR=libblastrampoline
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
            # Dependency("TensorRT_jll"; platforms = cuda_platforms), # Building with TensorRT is not supported: https://github.com/pytorch/pytorch/issues/60228
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
        preferred_llvm_version = v"14",
        julia_compat = "1.9",
        augment_platform_block = CUDA.augment,
        lazy_artifacts = true)
end
