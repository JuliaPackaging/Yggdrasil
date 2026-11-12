using BinaryBuilder
using BinaryBuilderBase
using Pkg
using Base.BinaryPlatforms: arch, os, tags

version = v"1.31.1"

sources = AbstractSource[
    GitSource("https://github.com/microsoft/onnxruntime.git", "6af1a932e2286d5c58166085d24c68783033edee"),
]

# ONNX Runtime pins its third-party dependencies (protobuf, onnx, abseil, eigen, ...) in
# cmake/deps.txt and fetches them at configure time; it links them statically. Do not add
# protobuf/ONNX JLLs as dependencies: protobuf requires generated code and runtime to match
# exactly, and ORT's FetchContent would pick up a system copy if it found one. When
# cross-compiling (always, in BinaryBuilder), ORT also downloads the matching prebuilt
# `protoc` for the host.
script = raw"""
cd $WORKSPACE/srcdir

if [[ $target == *-w64-mingw32* ]]; then
    # Cross-compiling ONNX Runtime with MinGW isn't supported; repackage the upstream build.
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
    exit 0
fi

apk del cmake # Need CMake >= 3.28, from CMake_jll

cmake_extra_args=()

if [[ $bb_full_target == *-cuda+* ]]; then
    export CUDA_PATH=$prefix/cuda
    if [[ $target == aarch64-* ]]; then
        # nvcc must run on the x86_64 host: use the x86_64 compiler with the target's SDK.
        rm -rf $CUDA_PATH/bin $CUDA_PATH/nvvm/bin $CUDA_PATH/nvvm/lib64
        cp -a cuda_nvcc-linux-x86_64-*-archive/bin $CUDA_PATH/bin
        cp -a libnvvm-linux-x86_64-*-archive/nvvm/{bin,lib64} $CUDA_PATH/nvvm/
    fi
    [[ -e $CUDA_PATH/lib64 ]] || ln -s lib $CUDA_PATH/lib64

    # CUDA compilation can run out of space in the default temporary directory
    mkdir -p $WORKSPACE/tmpdir
    export TMPDIR=$WORKSPACE/tmpdir

    cmake_extra_args+=(
        -DCMAKE_CUDA_COMPILER=$CUDA_PATH/bin/nvcc
        -DCMAKE_CUDA_HOST_COMPILER=$(which $CXX)
        -DCUDAToolkit_ROOT=$CUDA_PATH
        -DCMAKE_CUDA_ARCHITECTURES="75-real;80-real;86-real;89-real;90-real;100-real;120"
        -Donnxruntime_USE_CUDA=ON
        -Donnxruntime_CUDA_HOME=$CUDA_PATH
        -Donnxruntime_CUDNN_HOME=$prefix
        -Donnxruntime_NVCC_THREADS=1
    )
fi

if [[ $target == aarch64-apple-darwin* ]]; then
    cmake_extra_args+=(-DCMAKE_OSX_ARCHITECTURES=arm64)
elif [[ $target == x86_64-apple-darwin* ]]; then
    cmake_extra_args+=(-DCMAKE_OSX_ARCHITECTURES=x86_64)
fi

cd onnxruntime
cmake \
    -S cmake \
    -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DPython_EXECUTABLE=$(which python3) \
    -Donnxruntime_BUILD_SHARED_LIB=ON \
    -Donnxruntime_BUILD_UNIT_TESTS=OFF \
    -Donnxruntime_DISABLE_RTTI=OFF \
    -Donnxruntime_ENABLE_CPUINFO=OFF \
    "${cmake_extra_args[@]}"
cmake --build build --parallel $nproc
cmake --install build
install_license LICENSE

if [[ $bb_full_target == *-cuda+* ]] && [[ $target == aarch64-* ]]; then
    rm -rf $prefix/cuda
fi
"""

function platform_exclude_filter(p::Platform)
    libc(p) == "musl" || # onnxruntime/core/platform/posix/stacktrace.cc: execinfo.h: No such file or directory
    arch(p) == "riscv64" ||
    arch(p) == "i686" || # No upstream Windows build; Linux source build fails to link libonnxruntime.so
    Sys.isfreebsd(p)
end
platforms = supported_platforms(; exclude=platform_exclude_filter)
platforms = expand_cxxstring_abis(platforms; skip=!Sys.islinux)

products = Product[
    LibraryProduct(["libonnxruntime", "onnxruntime"], :libonnxruntime)
]

dependencies = AbstractDependency[
    HostBuildDependency(PackageSpec(name="CMake_jll")),  # Need CMake >= 3.28
]

# ONNX Runtime requires GCC >= 11.1 (C++20)
preferred_gcc_version = v"12"
