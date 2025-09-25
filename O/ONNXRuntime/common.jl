using BinaryBuilder
using BinaryBuilderBase
using Pkg

sources = AbstractSource[
    GitSource("https://github.com/microsoft/onnxruntime.git", "26250ae74d2c9a3c6860625ba4a147ddfb936907"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
apk del cmake # Need CMake >= 3.26
apk del python2 # Need Python >= 3.8

cd $WORKSPACE/srcdir

cuda_version=${bb_full_target##*-cuda+}
if [[ $target != *-w64-mingw32* ]]; then
    if [[ $bb_full_target == x86_64-linux-gnu-*-cuda* ]]; then
        export CUDA_PATH=$prefix/cuda
        ln -s $prefix/cuda/lib $prefix/cuda/lib64

        # CUDA compilation can run out of storage
        mkdir $WORKSPACE/tmpdir
        export TMPDIR=$WORKSPACE/tmpdir

        cmake_extra_args=(
            -DCUDAToolkit_ROOT=$CUDA_PATH
            -Donnxruntime_CUDA_HOME=$CUDA_PATH
            -Donnxruntime_CUDNN_HOME=$prefix
            -Donnxruntime_TENSORRT_HOME=$prefix
            -Donnxruntime_USE_CUDA=ON
            -Donnxruntime_USE_TENSORRT=ON
        )
    fi

    # Cross-compiling for aarch64-apple-darwin on x86_64 requires setting arch.: https://github.com/microsoft/onnxruntime/blob/29209784dd53965fb9fef0ebc1c837fe16574d09/docs/build/inferencing.md#macos
    if [[ $target == aarch64-apple-darwin* ]]; then
        cmake_extra_args+=(
            -DCMAKE_OSX_ARCHITECTURES=arm64
        )
    elif [[ $target == x86_64-apple-darwin* ]]; then
        cmake_extra_args+=(
            -DCMAKE_OSX_ARCHITECTURES=x86_64
        )
    fi

    cd onnxruntime

    atomic_patch -p1 ../patches/aarch64-linux-bfloat16-float16-cmake.patch
    atomic_patch -p1 ../patches/aarch64-linux-cmake-3.patch

    git submodule update --init --recursive --depth 1 --jobs $nproc
    cmake \
        -B build \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DONNX_CUSTOM_PROTOC_EXECUTABLE=$host_bindir/protoc \
        -Donnxruntime_BUILD_SHARED_LIB=ON \
        -Donnxruntime_BUILD_UNIT_TESTS=OFF \
        -Donnxruntime_DISABLE_RTTI=OFF \
        -Donnxruntime_ENABLE_CPUINFO=OFF \
        "${cmake_extra_args[@]}" \
        $WORKSPACE/srcdir/onnxruntime/cmake
    cmake --build build --parallel $nproc
    cmake --install build
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

if [[ $bb_full_target == aarch64-linux-gnu*-cuda* ]]; then
    cd $WORKSPACE/srcdir
    unzip -d onnxruntime-$target-cuda onnxruntime-$target-cuda.whl
    mkdir -p $libdir
    find onnxruntime-$target-cuda/onnxruntime_gpu*.data/purelib/onnxruntime/capi -name *.so* -not -name *py* | xargs -Isrc cp -av src $libdir
fi
"""

function platform_exclude_filter(p::Platform)
    libc(p) == "musl" # onnxruntime/core/platform/posix/stacktrace.cc:7:10: fatal error: execinfo.h: No such file or directory
end
platforms = supported_platforms(; exclude=platform_exclude_filter)
platforms = expand_cxxstring_abis(platforms; skip=!Sys.islinux)

products = Product[
    LibraryProduct(["libonnxruntime", "onnxruntime"], :libonnxruntime)
]

dependencies = AbstractDependency[
    HostBuildDependency(PackageSpec("protoc_jll", v"3.21.12")),
    HostBuildDependency(PackageSpec(name="CMake_jll")),  # Need CMake >= 3.26
]

