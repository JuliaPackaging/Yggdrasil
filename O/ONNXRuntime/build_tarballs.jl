# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "ONNXRuntime"
version = v"1.10.0"

# Cf. https://onnxruntime.ai/docs/execution-providers/CUDA-ExecutionProvider.html#requirements
# Cf. https://onnxruntime.ai/docs/execution-providers/TensorRT-ExecutionProvider.html#requirements
cuda_versions = [
    v"10.2",
    v"11.3",
]
cudnn_version = v"8.2.4"
tensorrt_version = v"8.0.1"

cudnn_compat = string(cudnn_version.major)
tensorrt_compat = string(tensorrt_version.major)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/onnxruntime.git", "0d9030e79888d1d5828730b254fedc53c7b640c1"),
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-$version.zip", "a0c6db3cff65bd282f6ba4a57789e619c27e55203321aa08c023019fe9da50d7"; unpack_target="onnxruntime-x86_64-w64-mingw32"),
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x86-$version.zip", "fd1680fa7248ec334efc2564086e9c5e0d6db78337b55ec32e7b666164bdb88c"; unpack_target="onnxruntime-i686-w64-mingw32"),
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-gpu-$version.zip", "0da11b8d953fad4ec75f87bb894f72dea511a3940cff2f4dad37451586d1ebbc"; unpack_target="onnxruntime-x86_64-w64-mingw32-cuda"),
    # aarch64-linux-gnu binaries for NVIDIA Jetson from NVIDIA-managed Jetson Zoo: https://elinux.org/Jetson_Zoo#ONNX_Runtime
    FileSource("https://nvidia.box.com/shared/static/jy7nqva7l88mq9i8bw3g3sklzf4kccn2.whl", "a608b7a4a4fc6ad5c90d6005edbfe0851847b991b08aafff4549bbbbdb938bf6"; filename = "onnxruntime-aarch64-linux-gnu-cuda.whl"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

if [[ $target != *-w64-mingw32* ]]; then
    if [[ $bb_full_target == x86_64-linux-gnu-*-cuda* && $bb_full_target != *-cuda+none* ]]; then
        cuda_version=`echo $bb_full_target | sed -E -e 's/.*cuda\+([0-9]+\.[0-9]+).*/\1/'`
        cuda_version_major=`echo $cuda_version | cut -d . -f 1`
        cuda_version_minor=`echo $cuda_version | cut -d . -f 2`
        cuda_sdk_path=$prefix/cuda
        export PATH=$PATH:$cuda_sdk_path/bin
        mkdir $WORKSPACE/tmpdir
        export TMPDIR=$WORKSPACE/tmpdir
        cmake_extra_args=(
            "-DCMAKE_CUDA_FLAGS=-cudart shared"
            "-Donnxruntime_CUDA_HOME=$cuda_sdk_path"
            "-Donnxruntime_CUDNN_HOME=$prefix"
            "-Donnxruntime_USE_CUDA=ON"
            "-Donnxruntime_USE_TENSORRT=ON"
        )
    fi

    # Cross-compiling for aarch64-apple-darwin on x86_64 requires setting arch.: https://github.com/microsoft/onnxruntime/blob/v1.10.0/cmake/CMakeLists.txt#L186
    if [[ $target == aarch64-apple-darwin* ]]; then
        cmake_extra_args+=("-DCMAKE_OSX_ARCHITECTURES='arm64'")
    fi

    cd onnxruntime
    git submodule update --init --recursive --depth 1 --jobs $nproc
    mkdir build
    cd build
    cmake \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DONNX_CUSTOM_PROTOC_EXECUTABLE=$host_bindir/protoc \
        -Donnxruntime_BUILD_SHARED_LIB=ON \
        -Donnxruntime_BUILD_UNIT_TESTS=OFF \
        -Donnxruntime_DISABLE_RTTI=OFF \
        "${cmake_extra_args[@]}" \
        $WORKSPACE/srcdir/onnxruntime/cmake
    make -j $nproc
    make install
    install_license $WORKSPACE/srcdir/onnxruntime/LICENSE
else
    if [[ $bb_full_target == *-cuda+none* ]]; then
        srcdir=onnxruntime-$target
    else
        srcdir=onnxruntime-$target-cuda
    fi
    chmod 755 $srcdir/onnxruntime-*/lib/*
    mkdir -p $includedir $libdir
    cp -av $srcdir/onnxruntime-*/include/* $includedir
    find $srcdir/onnxruntime-*/lib -not -type d | xargs -Isrc cp -av src $libdir
    install_license $srcdir/onnxruntime-*/LICENSE
fi

if [[ $bb_full_target == aarch64-linux-gnu*cuda* ]]; then
    cd $WORKSPACE/srcdir
    unzip -d onnxruntime-$target-cuda onnxruntime-$target-cuda.whl
    mkdir -p $libdir
    find onnxruntime-$target-cuda/onnxruntime_gpu*.data/purelib/onnxruntime/capi -name *.so* -not -name *py* | xargs -Isrc cp -av src $libdir
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
function platform_exclude_filter(p::Platform)
    libc(p) == "musl" ||
    p == Platform("i686", "Linux") || # No binary - and source build fails linking CXX shared library libonnxruntime.so
    Sys.isfreebsd(p)
end
platforms = supported_platforms(; exclude=platform_exclude_filter)
platforms = expand_cxxstring_abis(platforms; skip=!Sys.islinux)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libonnxruntime", "onnxruntime"], :libonnxruntime)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec("protoc_jll", v"3.16.1"))
]

augment_platform_block = CUDA.augment

builds = []
for cuda_version in [nothing, cuda_versions...], platform in platforms
    augmented_platform = deepcopy(platform)
    if isnothing(cuda_version)
        augmented_platform["cuda"] = "none"
    else
        if (
                CUDA.is_supported(platform)
                && (
                    (arch(platform) == "aarch64" && Sys.islinux(platform) && Base.thismajor(cuda_version) == v"10")
                    || (arch(platform) == "x86_64" && Sys.islinux(platform) && Base.thismajor(cuda_version) == v"11")
                )
            ) || (
                arch(platform) == "x86_64" && Sys.iswindows(platform) && Base.thismajor(cuda_version) == v"11"
            )
            augmented_platform["cuda"] = CUDA.platform(cuda_version)
        else
            continue
        end
    end
    should_build_platform(triplet(augmented_platform)) || continue
    platform_dependencies = BinaryBuilder.AbstractDependency[]
    append!(platform_dependencies, dependencies)
    if !isnothing(cuda_version)
        if Base.thisminor(cuda_version) != v"11.3"
            append!(platform_dependencies, CUDA.required_dependencies(augmented_platform))
        else
            append!(platform_dependencies, [
                BuildDependency(PackageSpec("CUDA_full_jll", v"11.3.1")),
                Dependency("CUDA_Runtime_jll", v"0.7.0"), # Using Dependency with build version v"0.7.0" to get support for cuda = "11.3"
            ])
        end
        append!(platform_dependencies, [
            Dependency(get_addable_spec("CUDNN_jll", v"8.2.4+0"); compat = cudnn_compat), # Using v"8.2.4+0" to get support for cuda = "11.3"
            Dependency("TensorRT_jll", tensorrt_version; compat = tensorrt_compat),
            Dependency("Zlib_jll"),
        ])
    end
    push!(builds, (;
        platforms=[augmented_platform],
        dependencies=platform_dependencies,
    ))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, sources, script,
                   build.platforms, products, build.dependencies;
                   julia_compat="1.6",
                   augment_platform_block,
                   preferred_gcc_version = v"8")
end
