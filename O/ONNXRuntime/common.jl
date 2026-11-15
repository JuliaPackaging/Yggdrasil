using BinaryBuilder
using BinaryBuilderBase
using Pkg

sources = AbstractSource[
    GitSource("https://github.com/microsoft/onnxruntime.git", "fab30a46491a40f5e4c968b80e8a59acbbb91b53"; tag="v$(version)"),
]

script = raw"""
apk del cmake # Need CMake >= 3.28

cd $WORKSPACE/srcdir

cuda_version=${bb_full_target##*-cuda+}
if [[ $target != *-w64-mingw32* ]]; then
    if [[ $bb_full_target == *-cuda+* ]]; then
        export CUDA_PATH=$prefix/cuda
        ln -s $prefix/cuda/lib $prefix/cuda/lib64
        if [[ $target == aarch64-* ]]; then
            export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
            rm -rf $CUDA_PATH/bin $CUDA_PATH/nvvm/bin $CUDA_PATH/nvvm/lib64
            cp -a cuda_nvcc-linux-x86_64-*-archive/bin $CUDA_PATH/bin
            if compgen -G "libnvvm-linux-x86_64-*-archive" > /dev/null; then
                cp -a libnvvm-linux-x86_64-*-archive/nvvm/{bin,lib64} $CUDA_PATH/nvvm/
            else
                cp -a cuda_nvcc-linux-x86_64-*-archive/nvvm/{bin,lib64} $CUDA_PATH/nvvm/
            fi
        fi

        # CUDA compilation can run out of storage
        mkdir $WORKSPACE/tmpdir
        export TMPDIR=$WORKSPACE/tmpdir

        cmake_extra_args=(
            -DCMAKE_CUDA_COMPILER=$CUDA_PATH/bin/nvcc
            -DCMAKE_CUDA_HOST_COMPILER=$(which $CXX)
            -DCUDAToolkit_ROOT=$CUDA_PATH
            -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}"
            -Donnxruntime_CUDA_HOME=$CUDA_PATH
            -Donnxruntime_CUDNN_HOME=$prefix
            -Donnxruntime_NVCC_THREADS=1
            -Donnxruntime_TENSORRT_HOME=$prefix
            -Donnxruntime_USE_CUDA=ON
            -Donnxruntime_USE_TENSORRT=ON
            -Donnxruntime_USE_TENSORRT_BUILTIN_PARSER=ON
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
    elif [[ $target == arm-* ]]; then
        # lock_microarchitecture = false drops the wrappers' armv7l flags, and MLAS requires NEON
        export CFLAGS="-march=armv7-a -mtune=generic-armv7-a -mfpu=neon -mfloat-abi=hard"
        export CXXFLAGS="${CFLAGS}" ASMFLAGS="${CFLAGS}"
    elif [[ $target == powerpc64le-* ]]; then
        # Missing from glibc 2.17; MLAS uses them to detect POWER9
        export CXXFLAGS="-DAT_HWCAP2=26 -DPPC_FEATURE2_ARCH_3_00=0x00800000"
    fi

    cd onnxruntime

    # GCC 12 false positives (-Wrestrict) trip ORT's COMPILE_WARNING_AS_ERROR
    cmake \
        -B build \
        --compile-no-warning-as-error \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DPython_EXECUTABLE=$(which python3) \
        -Donnxruntime_BUILD_SHARED_LIB=ON \
        -Donnxruntime_BUILD_UNIT_TESTS=OFF \
        -Donnxruntime_DISABLE_RTTI=OFF \
        -Donnxruntime_ENABLE_CPUINFO=OFF \
        "${cmake_extra_args[@]}" \
        $WORKSPACE/srcdir/onnxruntime/cmake
    cmake --build build --parallel $nproc
    cmake --install build
    install_license $WORKSPACE/srcdir/onnxruntime/{LICENSE,ThirdPartyNotices.txt}

    if [[ $bb_full_target == *-cuda+* ]]; then
        rm -rf $prefix/cuda
    fi
else
    if [[ $bb_full_target == *-cuda* ]]; then
        srcdir=onnxruntime-$target-cuda+$cuda_version
    else
        srcdir=onnxruntime-$target
    fi
    chmod 755 $srcdir/onnxruntime-*/lib/*
    mkdir -p $includedir/onnxruntime $libdir
    cp -av $srcdir/onnxruntime-*/include/* $includedir/onnxruntime
    find $srcdir/onnxruntime-*/lib -not -type d -not -name '*.pdb' | xargs -Isrc cp -av src $libdir
    install_license $srcdir/onnxruntime-*/{LICENSE,ThirdPartyNotices.txt}
fi
"""

function platform_exclude_filter(p::Platform)
    libc(p) == "musl" || # onnxruntime/core/platform/posix/stacktrace.cc:7:10: fatal error: execinfo.h: No such file or directory
    arch(p) == "armv6l" || # MLAS requires NEON on 32-bit ARM
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

preferred_gcc_version = v"12" # C++20
