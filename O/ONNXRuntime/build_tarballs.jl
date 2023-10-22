# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "ONNXRuntime"
version = v"1.10.0"

# Cf. https://onnxruntime.ai/docs/execution-providers/CUDA-ExecutionProvider.html#requirements
# Cf. https://onnxruntime.ai/docs/execution-providers/TensorRT-ExecutionProvider.html#requirements
cuda_versions = [
    v"11.3.1", # Using 11.3, and not 11.4, to be compatible with TensorRT (JLL) v8.0.1 (which includes aarch64 support)
]
cuda_aarch64_tag = "10.2"
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
    if [[ $bb_full_target == x86_64-linux-gnu-*-cuda* ]]; then
        cuda_version=`echo $bb_full_target | sed -E -e 's/.*cuda\+([0-9]+\.[0-9]+).*/\1/'`
        cuda_version_major=`echo $cuda_version | cut -d . -f 1`
        cuda_version_minor=`echo $cuda_version | cut -d . -f 2`
        cuda_full_path=$prefix/cuda
        export PATH=$PATH:$cuda_full_path/bin
        mkdir $WORKSPACE/tmpdir
        export TMPDIR=$WORKSPACE/tmpdir
        cmake_extra_args=(
            "-DCMAKE_CUDA_FLAGS=-cudart shared"
            "-Donnxruntime_CUDA_HOME=$cuda_full_path"
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
    if [[ $bb_full_target == *-cuda* ]]; then
        srcdir=onnxruntime-$target-cuda
    else
        srcdir=onnxruntime-$target
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

cuda_platforms = Platform[]
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    for p in [
        Platform("x86_64", "Linux"; cuda = cuda_tag),
        Platform("x86_64", "Windows"; cuda = cuda_tag)
    ]
        push!(cuda_platforms, p)
    end
end
cuda_platforms = expand_cxxstring_abis(cuda_platforms; skip=!Sys.islinux)
push!(cuda_platforms, Platform("aarch64", "Linux"; cuda = cuda_aarch64_tag))

for p in cuda_platforms
    push!(platforms, p)
end

# The products that we will ensure are always built
products = [
    LibraryProduct(["libonnxruntime", "onnxruntime"], :libonnxruntime)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CUDNN_jll", cudnn_version;
        compat = cudnn_compat,
        platforms = cuda_platforms),
    Dependency("TensorRT_jll", tensorrt_version;
        compat = tensorrt_compat,
        platforms = cuda_platforms),
    Dependency("Zlib_jll"; platforms = cuda_platforms),
    BuildDependency(PackageSpec("CUDA_full_jll", first(cuda_versions)); platforms = cuda_platforms),
    HostBuildDependency(PackageSpec("protoc_jll", v"3.16.1"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    augment_platform_block = CUDA.augment,
    julia_compat = "1.6",
    preferred_gcc_version = v"8")
