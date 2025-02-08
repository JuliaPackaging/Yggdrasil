using BinaryBuilder
using BinaryBuilderBase
using Pkg

sources = AbstractSource[
    GitSource("https://github.com/microsoft/onnxruntime.git", "26250ae74d2c9a3c6860625ba4a147ddfb936907"),
]

script = raw"""
apk del cmake # Need CMake >= 3.26

cd $WORKSPACE/srcdir

cuda_version=${bb_full_target##*-cuda+}
if [[ $target != *-w64-mingw32* ]]; then
    if [[ $bb_full_target == x86_64-linux-gnu-*-cuda* ]]; then
        export CUDA_PATH="$prefix/cuda"
        mkdir $WORKSPACE/tmpdir
        export TMPDIR=$WORKSPACE/tmpdir
        cmake_extra_args=(
            -DCUDAToolkit_ROOT=$CUDA_PATH
            -Donnxruntime_CUDA_HOME=$CUDA_PATH
            -Donnxruntime_CUDNN_HOME=$prefix
            -Donnxruntime_USE_CUDA=ON
            -Donnxruntime_USE_TENSORRT=ON
        )
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

if [[ $bb_full_target == aarch64-linux-gnu*-cuda* ]]; then
    cd $WORKSPACE/srcdir
    unzip -d onnxruntime-$target-cuda onnxruntime-$target-cuda.whl
    mkdir -p $libdir
    find onnxruntime-$target-cuda/onnxruntime_gpu*.data/purelib/onnxruntime/capi -name *.so* -not -name *py* | xargs -Isrc cp -av src $libdir
fi
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms; skip=!Sys.islinux)

products = Product[
    LibraryProduct(["libonnxruntime", "onnxruntime"], :libonnxruntime)
]

dependencies = AbstractDependency[
    HostBuildDependency(PackageSpec("protoc_jll", v"3.16.1")),
    HostBuildDependency(PackageSpec(name="CMake_jll")),  # Need CMake >= 3.26
]

