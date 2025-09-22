using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "Reactant"
repo = "https://github.com/EnzymeAD/Reactant.jl.git"
version = v"0.0.241"

sources = [
   GitSource(repo, "7d8866e6862bcebb876e4d970798557dff773020"),
   ArchiveSource("https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.7%2B6/OpenJDK21U-jdk_x64_alpine-linux_hotspot_21.0.7_6.tar.gz", "79ecc4b213d21ae5c389bea13c6ed23ca4804a45b7b076983356c28105580013"),
   ArchiveSource("https://github.com/JuliaBinaryWrappers/Bazel_jll.jl/releases/download/Bazel-v7.6.1+0/Bazel.v7.6.1.x86_64-linux-musl-cxx03.tar.gz", "01ac6c083551796f1f070b0dc9c46248e6c49e01e21040b0c158f6e613733345")
]

# Bash recipe for building across all platforms
script = raw"""
export JAVA_HOME="`pwd`/jdk-21.0.7+6"
export BAZEL="`pwd`/bin/bazel"

cd Reactant.jl/deps/ReactantExtra

echo Clang version: $(clang --version)
echo GCC version: $(gcc --version)

GCC_VERSION=$(gcc --version | head -1 | awk '{ print $3 }')
GCC_MAJOR_VERSION=$(echo "${GCC_VERSION}" | cut -d. -f1)

if [[ "${target}" == *-apple-darwin* ]]; then
    # Compiling LLVM components within XLA requires macOS SDK 10.14
    # and then we use `std::reinterpret_pointer_cast` in ReactantExtra
    # which requires macOS SDK 11.3.
    pushd $WORKSPACE/srcdir/MacOSX11.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    rm -rf /opt/${target}/${target}/sys-root/usr/include/libxml2
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi

if [[ "${bb_full_target}" == *gpu+rocm* ]]; then
    export ROCM_PATH=$WORKSPACE/srcdir
    ln -s $ROCM_PATH/lib/llvm/amdgcn $ROCM_PATH/amdgcn
    apk add coreutils
fi

if [[ "${bb_full_target}" == *gpu+rocm* ]]; then
    git clone https://github.com/ROCm/TheRock
    cd TheRock


    apk del cmake

    bash ${WORKSPACE}/srcdir/miniconda.sh -b -p ${host_bindir}/miniconda
    ${host_bindir}/miniconda/bin/python -m venv .venv && source .venv/bin/activate
    # pip install -r requirements.txt
    
    python ./build_tools/fetch_sources.py

    export CCACHE_DIR=/root/.ccache
    export CCACHE_NOHASHDIR=yes
    
    sed -i.bak1 -e "s/_extra_llvm_cmake_args}/_extra_llvm_cmake_args} -DCOMGR_BUILD_SHARED_LIBS=OFF/g" compiler/CMakeLists.txt

    cmake -B build -GNinja .  -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DTHEROCK_AMDGPU_TARGETS="gfx942;gfx1030;gfx1100;gfx1200;gfx1201" -DTHEROCK_AMDGPU_DIST_BUNDLE_NAME=reactant -DTHEROCK_ENABLE_ROCPROF_TRACE_DECODER_BINARY=OFF -DCMAKE_C_COMPILER=$HOSTCC -DCMAKE_CXX_COMPILER=$HOSTCXX
    cmake --build build
    cd ..
fi

mkdir -p .local/bin
export LOCAL="`pwd`/.local/bin"
export PATH="$LOCAL:$PATH"

ln -s `which ar` /usr/bin/ar

mkdir .bazhome
export HOME=`pwd`/.bazhome

mkdir .tmp
export TMPDIR=`pwd`/.tmp
export TMP=$TMPDIR
export TEMP=$TMPDIR
export BAZEL_CXXOPTS="-std=c++17"
BAZEL_FLAGS=()
BAZEL_BUILD_FLAGS=(-c $MODE)

# don't run out of temporary space
BAZEL_FLAGS+=(--output_user_root=$WORKSPACE/bazel_root)
BAZEL_FLAGS+=(--server_javabase=$JAVA_HOME)
# BAZEL_FLAGS+=(--extra_toolchains=@local_jdk//:all)

BAZEL_BUILD_FLAGS+=(--jobs ${nproc})

# Use ccache to speedup re-builds
BAZEL_BUILD_FLAGS+=(--action_env=USE_CCACHE=${USE_CCACHE} --action_env=CCACHE_DIR=/root/.ccache)
BAZEL_BUILD_FLAGS+=(--action_env=CCACHE_NOHASHDIR=yes)
# # Set `SUPER_VERBOSE` to a non empty string to make the compiler wrappers more
# # verbose. Useful for debugging.
# BAZEL_BUILD_FLAGS+=(--action_env=SUPER_VERBOSE=true)

BAZEL_BUILD_FLAGS+=(--verbose_failures)
BAZEL_BUILD_FLAGS+=(--cxxopt=-std=c++17 --host_cxxopt=-std=c++17)
BAZEL_BUILD_FLAGS+=(--cxxopt=-DTCP_USER_TIMEOUT=0)
BAZEL_BUILD_FLAGS+=(--check_visibility=false)
BAZEL_BUILD_FLAGS+=(--build_tag_filters=-jlrule)
BAZEL_BUILD_FLAGS+=(--experimental_cc_shared_library)
BAZEL_BUILD_FLAGS+=(--toolchain_resolution_debug='@bazel_tools//tools/cpp:toolchain_type')

# Always link with lld
BAZEL_BUILD_FLAGS+=(--linkopt=-fuse-ld=lld)

# Disable enabled-by-default TensorFlow features that we don't care about.
BAZEL_BUILD_FLAGS+=(--define=no_aws_support=true)
BAZEL_BUILD_FLAGS+=(--define=no_gcp_support=true)
BAZEL_BUILD_FLAGS+=(--define=no_hdfs_support=true)
BAZEL_BUILD_FLAGS+=(--define=no_kafka_support=true)
BAZEL_BUILD_FLAGS+=(--define=no_ignite_support=true)
BAZEL_BUILD_FLAGS+=(--define=grpc_no_ares=true)

BAZEL_BUILD_FLAGS+=(--define=llvm_enable_zlib=false)
BAZEL_BUILD_FLAGS+=(--verbose_failures)

BAZEL_BUILD_FLAGS+=(--action_env=TMP=$TMPDIR --action_env=TEMP=$TMPDIR --action_env=TMPDIR=$TMPDIR --sandbox_tmpfs_path=$TMPDIR)
BAZEL_BUILD_FLAGS+=(--host_cpu=k8)
BAZEL_BUILD_FLAGS+=(--host_platform=//:linux_x86_64)
BAZEL_BUILD_FLAGS+=(--host_crosstool_top=@//:ygg_cross_compile_toolchain_suite)
# BAZEL_BUILD_FLAGS+=(--extra_execution_platforms=@xla//tools/toolchains/cross_compile/config:linux_x86_64)

if [[ "${target}" == x86_64-apple-darwin* ]]; then
   BAZEL_CPU=darwin
elif [[ "${target}" == aarch64-apple-darwin* ]]; then
   BAZEL_CPU=darwin_arm64
elif [[ "${target}" == x86_64-linux-* ]]; then
   BAZEL_CPU=k8
elif [[ "${target}" == aarch64-linux-* ]]; then
   BAZEL_CPU=aarch64
elif [[ "${target}" == x86_64-w64-mingw32* ]]; then
   BAZEL_CPU=x64_windows
elif [[ "${target}" == aarch64-mingw32* ]]; then
   BAZEL_CPU=arm64_windows
fi

echo "register_toolchains(\\"//:cc_toolchain_for_ygg_host\\")" >> WORKSPACE

if [[ "${target}" == *-darwin* ]]; then
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_x86_32_1=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_x86_64_1=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_x86_64_2=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_aarch64=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_ppc64=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_s390x=false)
    BAZEL_BUILD_FLAGS+=(--apple_platform_type=macos)
    BAZEL_BUILD_FLAGS+=(--define=no_nccl_support=true)
    BAZEL_BUILD_FLAGS+=(--define=build_with_mkl=false --define=enable_mkl=false --define=build_with_mkl_aarch64=false)
    BAZEL_BUILD_FLAGS+=(--@xla//xla/tsl/framework/contraction:disable_onednn_contraction_kernel=True)

    rm /opt/*apple*/bin/clang-8
    rm /opt/*apple*/bin/clang

    sed -i.bak1 -e "/__cpp_lib_hardware_interference_size/d" \
	            /opt/*apple*/*apple*/sys-root/usr/include/c++/v1/version

    if [[ "${target}" == x86_64* ]]; then
        BAZEL_BUILD_FLAGS+=(--platforms=@//:darwin_x86_64)
        BAZEL_BUILD_FLAGS+=(--cpu=${BAZEL_CPU})
	echo "register_toolchains(\\"//:cc_toolchain_for_ygg_darwin_x86\\")" >> WORKSPACE
    elif [[ "${target}" == aarch64-* ]]; then
        BAZEL_BUILD_FLAGS+=(--platforms=@//:darwin_arm64)
        BAZEL_BUILD_FLAGS+=(--cpu=${BAZEL_CPU})
	echo "register_toolchains(\\"//:cc_toolchain_for_ygg_darwin_arm64\\")" >> WORKSPACE
    fi
    BAZEL_BUILD_FLAGS+=(--linkopt=-twolevel_namespace)
    BAZEL_BUILD_FLAGS+=(--crosstool_top=@//:ygg_cross_compile_toolchain_suite)
    BAZEL_BUILD_FLAGS+=(--define=clang_macos_x86_64=true)
    # `using_clang` comes from Enzyme-JAX, to handle clang-specific options.
    BAZEL_BUILD_FLAGS+=(--define=using_clang=true)
    BAZEL_BUILD_FLAGS+=(--define HAVE_LINK_H=0)
    export MACOSX_DEPLOYMENT_TARGET=11.3
    BAZEL_BUILD_FLAGS+=(--macos_minimum_os=${MACOSX_DEPLOYMENT_TARGET})
    BAZEL_BUILD_FLAGS+=(--action_env=MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET})
    BAZEL_BUILD_FLAGS+=(--host_action_env=MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET})
    BAZEL_BUILD_FLAGS+=(--repo_env=MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET})
    BAZEL_BUILD_FLAGS+=(--test_env=MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET})
    BAZEL_BUILD_FLAGS+=(--incompatible_remove_legacy_whole_archive)
    BAZEL_BUILD_FLAGS+=(--nolegacy_whole_archive)
fi

if [[ "${target}" == *-mingw* ]]; then
    sed -i 's/noincompatible_enable_cc_toolchain_resolution/incompatible_enable_cc_toolchain_resolution/' .bazelrc
    BAZEL_BUILD_FLAGS+=(--compiler=mingw-gcc)
    BAZEL_BUILD_FLAGS+=(--copt=-D_USE_MATH_DEFINES)
    BAZEL_BUILD_FLAGS+=(--copt=-DWIN32_LEAN_AND_MEAN)
    BAZEL_BUILD_FLAGS+=(--copt=-DNOGDI)
    # BAZEL_BUILD_FLAGS+=(--compiler=clang)
    BAZEL_BUILD_FLAGS+=(--define=using_clang=true)
    apk add --upgrade zlib --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main
    if [[ "${target}" == x86_64* ]]; then
        BAZEL_BUILD_FLAGS+=(--platforms=@//:win_x86_64)
        BAZEL_BUILD_FLAGS+=(--cpu=${BAZEL_CPU})
	echo "register_toolchains(\\"//:cc_toolchain_for_ygg_win_x86\\")" >> WORKSPACE
    elif [[ "${target}" == aarch64-* ]]; then
        BAZEL_BUILD_FLAGS+=(--platforms=@//:win_arm64)
        BAZEL_BUILD_FLAGS+=(--cpu=${BAZEL_CPU})
	echo "register_toolchains(\\"//:cc_toolchain_for_ygg_win_arm64\\")" >> WORKSPACE
    fi
fi

if [[ "${target}" == *-linux-* ]]; then
    sed -i "s/getopts \\"/getopts \\"p/g" /sbin/ldconfig
    mkdir -p .local/bin
    echo "#!/bin/sh" > .local/bin/ldconfig
    echo "" >> .local/bin/ldconfig
    chmod +x .local/bin/ldconfig
    export PATH="`pwd`/.local/bin:$PATH"
    BAZEL_BUILD_FLAGS+=(--copt=-Wno-error=cpp)

    if [[ "${target}" == x86_64-* ]]; then
        BAZEL_BUILD_FLAGS+=(--platforms=@//:linux_x86_64)
	echo "register_toolchains(\\"//:cc_toolchain_for_ygg_x86\\")" >> WORKSPACE
    elif [[ "${target}" == aarch64-* ]]; then
        BAZEL_BUILD_FLAGS+=(--crosstool_top=@//:ygg_cross_compile_toolchain_suite)
        BAZEL_BUILD_FLAGS+=(--platforms=@//:linux_aarch64)
        BAZEL_BUILD_FLAGS+=(--cpu=${BAZEL_CPU})
        BAZEL_BUILD_FLAGS+=(--@xla//xla/tsl/framework/contraction:disable_onednn_contraction_kernel=True)
	echo "register_toolchains(\\"//:cc_toolchain_for_ygg_aarch64\\")" >> WORKSPACE
    fi
fi

if [[ "${target}" == aarch64-* ]]; then
    BAZEL_BUILD_FLAGS+=(--copt=-D__ARM_FEATURE_AES=1)
    BAZEL_BUILD_FLAGS+=(--copt=-D__ARM_NEON=1)
    BAZEL_BUILD_FLAGS+=(--copt=-D__ARM_FEATURE_SHA2=1)
    BAZEL_BUILD_FLAGS+=(--copt=-DDNNL_ARCH_GENERIC=1)
    BAZEL_BUILD_FLAGS+=(--define=@xla//build_with_mkl_aarch64=true)
fi

if [[ "${bb_full_target}" == *gpu+cuda* ]]; then
    BAZEL_BUILD_FLAGS+=(--config=cuda)
    BAZEL_BUILD_FLAGS+=(--repo_env=HERMETIC_CUDA_VERSION="${HERMETIC_CUDA_VERSION}")
    if [[ "${HERMETIC_CUDA_VERSION}" == *13.* ]]; then
	BAZEL_BUILD_FLAGS+=(--repo_env=HERMETIC_CUDNN_VERSION="9.12.0")
	BAZEL_BUILD_FLAGS+=(--repo_env=HERMETIC_NVSHMEM_VERSION="3.3.20")
	BAZEL_BUILD_FLAGS+=(--repo_env HERMETIC_CUDA_COMPUTE_CAPABILITIES="sm_75,sm_80,sm_90,sm_100,compute_120")
    fi

    if [[ "${GCC_MAJOR_VERSION}" -le 12 && "${target}" == x86_64-* ]]; then
        # Someone wants to compile some code which requires flags not understood by GCC 12.
        BAZEL_BUILD_FLAGS+=(--define=xnn_enable_avxvnniint8=false)
    fi
    if [[ "${GCC_MAJOR_VERSION}" -le 11 && "${target}" == x86_64-* ]]; then
        # Someone wants to compile some code which requires flags not understood by GCC 11.
        BAZEL_BUILD_FLAGS+=(--define=xnn_enable_avx512fp16=false)
    fi

    if [[ "${target}" != x86_64-linux-gnu ]]; then
        # This is the standard `LD_LIBRARY_PATH` we have in our environment + `/usr/lib/csl-glibc-x86_64` to be able to run host `nvcc`/`ptxas`/`fatbinary` during compilation.
        export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib:/lib64:/lib:/workspace/x86_64-linux-musl-cxx11/destdir/lib:/workspace/x86_64-linux-musl-cxx11/destdir/lib64:/opt/x86_64-linux-musl/x86_64-linux-musl/lib64:/opt/x86_64-linux-musl/x86_64-linux-musl/lib:/opt/${target}/${target}/lib64:/opt/${target}/${target}/lib:/workspace/destdir/lib64"

        # Delete shared libc++ to force statically linking to it.
        rm -v "${prefix}/libcxx/lib/libc++.so"*

        BAZEL_BUILD_FLAGS+=(
            --repo_env=CUDA_REDIST_TARGET_PLATFORM="aarch64"
	    --repo_env=NVSHMEM_REDIST_TARGET_PLATFORM="aarch64"
            --linkopt="-L${prefix}/libcxx/lib"
	)
    else
        sed -i.bak1 -e "/nvcc/d" .bazelrc
        BAZEL_BUILD_FLAGS+=(
            --linkopt="-stdlib=libstdc++"
	)
    fi
    BAZEL_BUILD_FLAGS+=(
	    --action_env=CLANG_CUDA_COMPILER_PATH=$(which clang)
	    --define=using_clang=true
    )
fi

if [[ "${bb_full_target}" == *gpu+rocm* ]]; then
    BAZEL_BUILD_FLAGS+=(--config=rocm)

    if [[ "${GCC_MAJOR_VERSION}" -le 12 && "${target}" == x86_64-* ]]; then
        # Someone wants to compile some code which requires flags not understood by GCC 12.
        BAZEL_BUILD_FLAGS+=(--define=xnn_enable_avxvnniint8=false)
    fi
    if [[ "${GCC_MAJOR_VERSION}" -le 11 && "${target}" == x86_64-* ]]; then
        # Someone wants to compile some code which requires flags not understood by GCC 11.
        BAZEL_BUILD_FLAGS+=(--define=xnn_enable_avx512fp16=false)
    fi

    if [[ "${target}" != x86_64-linux-gnu ]]; then
        # This is the standard `LD_LIBRARY_PATH` we have in our environment + `/usr/lib/csl-glibc-x86_64` to be able to run host `nvcc`/`ptxas`/`fatbinary` during compilation.
        export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib:/lib64:/lib:/workspace/x86_64-linux-musl-cxx11/destdir/lib:/workspace/x86_64-linux-musl-cxx11/destdir/lib64:/opt/x86_64-linux-musl/x86_64-linux-musl/lib64:/opt/x86_64-linux-musl/x86_64-linux-musl/lib:/opt/${target}/${target}/lib64:/opt/${target}/${target}/lib:/workspace/destdir/lib64"

        BAZEL_BUILD_FLAGS+=(
            --linkopt="-L${prefix}/libcxx/lib"
	)
    else
        BAZEL_BUILD_FLAGS+=(
            --linkopt="-stdlib=libstdc++"
	)
    fi
    
    BAZEL_BUILD_FLAGS+=(--copt=-stdlib=libstdc++)

    # export HIPCC_ENV="--sysroot=/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root;-D_GLIBCXX_USE_CXX11_ABI=1;-stdlib=libstdc++;--gcc-install-dir=/opt/x86_64-linux-gnu/lib/gcc/x86_64-linux-gnu/13.2.0;-isystem/opt/x86_64-linux-gnu/x86_64-linux-gnu/include/c++/13.2.0"

	# 	--action_env=HIP_PATH=${prefix}/hip
	# 	--action_env=HSA_PATH=${prefix}
	# 	--action_env=HIP_CLANG_PATH=${prefix}/llvm/bin
	# 	--action_env=HIP_LIB_PATH=${prefix}/hip/lib
	# 	--action_env=DEVICE_LIB_PATH=${prefix}/amdgcn/bitcode
    # for hermetic rocm
    # apk add zlib

    BAZEL_BUILD_FLAGS+=(
		--action_env=ROCM_PATH=$ROCM_PATH
		--repo_env=ROCM_PATH=$ROCM_PATH
	
		# anything before 942 hits a 128-bit error
		--action_env=TF_ROCM_AMDGPU_TARGETS="gfx942,gfx1030,gfx1100,gfx1200,gfx1201"

                --linkopt="-L$ROCM_PATH/lib/rocm_sysdeps/lib"

		#--repo_env="OS=ubuntu_22.04"
		#--repo_env="ROCM_VERSION=$HERMETIC_ROCM_VERSION"
		#--@local_config_rocm//rocm:rocm_path_type=hermetic

		--copt=--sysroot=/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root
		--copt=--gcc-install-dir=/opt/x86_64-linux-gnu/lib/gcc/x86_64-linux-gnu/13.2.0
		--copt=-isystem=/workspace/bazel_root/097636303b1142f44508c1d8e3494e4b/external/local_config_rocm/rocm/rocm_dist/lib/llvm/lib/clang/20/include/cuda_wrappers
 		--copt=-isystem=/workspace/bazel_root/097636303b1142f44508c1d8e3494e4b/external/local_config_rocm/rocm/rocm_dist/lib/llvm/lib/clang/20/include
		--copt=-isystem=/opt/x86_64-linux-gnu/x86_64-linux-gnu/include/c++/13.2.0
		--copt=-isystem=/opt/x86_64-linux-gnu/x86_64-linux-gnu/include/c++/13.2.0/x86_64-linux-gnu
		--copt=-isystem=/opt/x86_64-linux-gnu/x86_64-linux-gnu/include/c++/13.2.0/backward
		--copt=-isystem=/opt/x86_64-linux-gnu/x86_64-linux-gnu/include
		--copt=-isystem=/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/include
	    --action_env=CLANG_COMPILER_PATH=$(which clang)
	    --define=using_clang=true
    )
fi

if [[ "${target}" == *-freebsd* ]]; then
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_x86_32_1=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_x86_64_1=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_x86_64_2=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_aarch64=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_ppc64=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_s390x=false)
    BAZEL_BUILD_FLAGS+=(--define=freebsd=true)
    BAZEL_BUILD_FLAGS+=(--cpu=freebsd)
fi

if [[ "${target}" == i686-* ]]; then
    BAZEL_BUILD_FLAGS+=(--define=build_with_mkl=false --define=enable_mkl=false)
fi

sed -i -e "s/BB_TARGET/${bb_target}/g" \
       -e "s/BB_FULL_TARGET/${bb_full_target}/g" \
       -e "s/GCC_VERSION/${GCC_VERSION}/g" \
       -e "s/BAZEL_CPU/${BAZEL_CPU}/g" \
       BUILD

export HERMETIC_PYTHON_VERSION=3.12

rm -f /workspace/srcdir/lib/libamd_comgr.so*

$BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]}

sed -i "s/^cc_library(/cc_library(linkstatic=True,/g" /workspace/bazel_root/*/external/llvm-raw/utils/bazel/llvm-project-overlay/mlir/BUILD.bazel
sed -i "s/name = \\"protoc\\"/name = \\"protoc\\", features=[\\"fully_static_link\\"]/g" /workspace/bazel_root/*/external/com_google_protobuf/BUILD.bazel

if [[ "${target}" == *-darwin* ]]; then
    $BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so || echo stage1
    if [[ "${target}" == aarch64-* ]]; then
        # The host compiler is called at some point, but the GCC installation
        # dir is wrong in the compiler wrapper because it takes the GCC version from
        # the target, which is different (only for aarch64-darwin, because we
        # have a special GCC). This is a bug in BinaryBuilderBase, we work
        # around it here for the time being.
        sed -i 's/12.0.1-iains/12.1.0/' "/opt/bin/x86_64-linux-musl-cxx11/x86_64-linux-musl-clang"*
    fi

    # sed -i.bak1 -e "s/\\"k8|/\\"${BAZEL_CPU}\\": \\":cc-compiler-k8\\", \\"k8|/g" \
    #             -e "s/cpu = \\"k8\\"/cpu = \\"${BAZEL_CPU}\\"/g" \
    #             /workspace/bazel_root/*/external/bazel_tools~cc_configure_extension~local_config_cc/BUILD
   
    # sed -i.bak2 -e "s/\\":cpu_aarch64\\":/\\"@platforms\/\/cpu:aarch64\\":/g" \
    #             /workspace/bazel_root/*/external/xla/third_party/highwayhash/highwayhash.BUILD

    # We expect the following bazel build command to fail to link at the end, because the
    # build system insists on linking with `-whole_archive` also on macOS.  Until we figure
    # out how to make it stop doing this we have to manually do this.  Any other error
    # before the final linking stage is unexpected and will have to be dealt with.
    $BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so || echo "Bazel build failed, proceed to manual linking, check if there are are non-linking errors"

    # Manually remove `whole-archive` directive for the linker
    sed -i.bak1 -e "/whole-archive/d" \
                -e "/gc-sections/d" \
                bazel-bin/libReactantExtra.so-2.params
    
    # # Show the params file for debugging, but convert newlines to spaces
    # cat bazel-bin/libReactantExtra.so-2.params | tr '\n' ' '
    # echo ""

    cc @bazel-bin/libReactantExtra.so-2.params
elif [[ "${target}" == *mingw32* ]]; then
    $BAZEL ${BAZEL_FLAGS[@]} build --repo_env=CC ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so || echo stage1
    sed -i.bak1 -e "s/PTHREADPOOL_WEAK//g" /workspace/bazel_root/*/external/pthreadpool/src/portable-api.c
    $BAZEL ${BAZEL_FLAGS[@]} build --repo_env=CC ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so || echo stage2
    sed -i.bak1 -e "/start-lib/d" \
		-e "/end-lib/d" \
                bazel-bin/libReactantExtra.so-2.params

    sed -i.bak1 -e "s/^ws2_32.lib/-lws2_32/g" \
		-e "s/^ntdll.lib/-lntdll/g" \
                bazel-bin/libReactantExtra.so-2.params

		echo "-lole32" >> bazel-bin/libReactantExtra.so-2.params
echo "-lshlwapi" >> bazel-bin/libReactantExtra.so-2.params
echo "-lshell32" >> bazel-bin/libReactantExtra.so-2.params
echo "-lshdocvw" >> bazel-bin/libReactantExtra.so-2.params
echo "-lshcore" >> bazel-bin/libReactantExtra.so-2.params
echo "-lcrypt32" >> bazel-bin/libReactantExtra.so-2.params
echo "-lbcrypt" >> bazel-bin/libReactantExtra.so-2.params
echo "-lmsvcrt" >> bazel-bin/libReactantExtra.so-2.params
echo "-luuid" >> bazel-bin/libReactantExtra.so-2.params


    clang @bazel-bin/libReactantExtra.so-2.params
else
    $BAZEL ${BAZEL_FLAGS[@]} build --repo_env=CC ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so
fi

rm -f bazel-bin/libReactantExtraLib*
rm -f bazel-bin/libReactant*params
mkdir -p ${libdir}

if [[ "${bb_full_target}" == *gpu+cuda* ]]; then
    rm -rf bazel-bin/_solib_local/*stub*/*so*
    cp -v bazel-bin/_solib_local/*/*so* ${libdir}
    cp -v bazel-ReactantExtra/external/nvidia_nvshmem/lib/libnvshmem_device.bc ${libdir}
    find bazel-bin
    find ${libdir}
    # cp -v /workspace/bazel_root/*/external/cuda_nccl/lib/libnccl.so.2 ${libdir}

    if [[ "${target}" == x86_64-linux-gnu ]]; then
        NVCC_DIR=(bazel-bin/libReactantExtra.so.runfiles/cuda_nvcc)
    else
        NVCC_DIR=(/workspace/srcdir/cuda_nvcc-*-archive)
    fi

    if [ -f "${NVCC_DIR[@]}/nvvm/libdevice/libdevice.10.bc" ]; then
        install -Dvm 644 "${NVCC_DIR[@]}/nvvm/libdevice/libdevice.10.bc" -t "${libdir}/cuda/nvvm/libdevice"
    else
    	install -Dvm 644 bazel-bin/libReactantExtra.so.runfiles/cuda_nvvm/nvvm/libdevice/libdevice.10.bc -t "${libdir}/cuda/nvvm/libdevice"
    fi

    install -Dvm 755 "${NVCC_DIR[@]}/bin/ptxas" -t "${libdir}/cuda/bin"
    install -Dvm 755 "${NVCC_DIR[@]}/bin/fatbinary" -t "${libdir}/cuda/bin"

    # Simplify ridiculously long rpath of `libReactantExtra.so`,
    # we moved all deps in `${libdir}` anyway.
    patchelf --set-rpath '$ORIGIN' bazel-bin/libReactantExtra.so

fi

if [[ "${bb_full_target}" == *gpu+rocm* ]]; then
    rm -rf bazel-bin/_solib_local/*stub*/*so*
    cp -v bazel-bin/_solib_local/*/*so* ${libdir}
    find bazel-bin
    find ${libdir}

    install -Dvm 755 \
        $ROCM_PATH/lib/rocm_sysdeps/lib/librocm_sysdeps_numa.so* \
        -t ${libdir}/rocm_sysdeps/lib

    install -Dvm 755 \
        $ROCM_PATH/lib/rocm_sysdeps/lib/librocm_sysdeps_z.so* \
        -t ${libdir}/rocm_sysdeps/lib

    install -Dvm 755 \
        $ROCM_PATH/lib/rocm_sysdeps/lib/librocm_sysdeps_bz2.so* \
        -t ${libdir}/rocm_sysdeps/lib

    install -Dvm 755 \
        $ROCM_PATH/lib/rocm_sysdeps/lib/librocm_sysdeps_zstd.so* \
        -t ${libdir}/rocm_sysdeps/lib

    install -Dvm 755 \
        $ROCM_PATH/lib/rocm_sysdeps/lib/librocm_sysdeps_elf.so* \
        -t ${libdir}/rocm_sysdeps/lib

    install -Dvm 755 \
        $ROCM_PATH/lib/rocm_sysdeps/lib/librocm_sysdeps_drm.so* \
        -t ${libdir}/rocm_sysdeps/lib

    install -Dvm 755 \
        $ROCM_PATH/lib/rocm_sysdeps/lib/librocm_sysdeps_drm_amdgpu.so* \
        -t ${libdir}/rocm_sysdeps/lib

    install -Dvm 755 \
        $ROCM_PATH/lib/libroctx64.so* \
        -t ${libdir}

    install -Dvm 755 \
        $ROCM_PATH/lib/librocfft.so* \
        -t ${libdir}

    install -Dvm 755 \
        $ROCM_PATH/lib/librocsparse.so* \
        -t ${libdir}

    install -Dvm 755 \
        $ROCM_PATH/lib/librocblas.so* \
        -t ${libdir}
    
    install -Dvm 755 \
        $ROCM_PATH/lib/libhiprtc.so* \
        -t ${libdir}
    
    install -Dvm 755 \
        $ROCM_PATH/lib/libhipblaslt.so* \
        -t ${libdir}
    
    install -Dvm 755 \
        $ROCM_PATH/lib/libamdhip64.so* \
        -t ${libdir}
    
    install -Dvm 755 \
        $ROCM_PATH/lib/librocroller.so* \
        -t ${libdir}
    
     install -Dvm 755 \
        $ROCM_PATH/lib/host-math/lib/libcholmod.so* \
       -t ${libdir}/host-math/lib
     
     install -Dvm 755 \
        $ROCM_PATH/lib/host-math/lib/libamd.so* \
       -t ${libdir}/host-math/lib
     
     install -Dvm 755 \
        $ROCM_PATH/lib/host-math/lib/libcamd.so* \
       -t ${libdir}/host-math/lib
     
     install -Dvm 755 \
        $ROCM_PATH/lib/host-math/lib/libccolamd.so* \
       -t ${libdir}/host-math/lib
     
     install -Dvm 755 \
        $ROCM_PATH/lib/host-math/lib/libcolamd.so* \
       -t ${libdir}/host-math/lib
     
     install -Dvm 755 \
        $ROCM_PATH/lib/host-math/lib/librocm-openblas.so* \
       -t ${libdir}/host-math/lib
     
     install -Dvm 755 \
        $ROCM_PATH/lib/host-math/lib/libsuitesparseconfig.so* \
       -t ${libdir}/host-math/lib
     
     install -Dvm 755 \
        $ROCM_PATH/lib/host-math/lib/libsuitesparseconfig.so* \
       -t ${libdir}/host-math/lib



     install -Dvm 755 \
        $ROCM_PATH/lib/llvm/lib/libLLVM.so.20.0git \
       -t ${libdir}/llvm/lib
    
     install -Dvm 755 \
        $ROCM_PATH/lib/llvm/amdgcn/bitcode/* \
       -t ${libdir}/llvm/amdgcn/bitcode

    # Simplify ridiculously long rpath of `libReactantExtra.so`,
    # we moved all deps in `${libdir}` anyway.
    patchelf --set-rpath '$ORIGIN:$ORIGIN/rocm_sysdeps/lib' bazel-bin/libReactantExtra.so

fi


install -Dvm 755 bazel-bin/libReactantExtra.so "${libdir}/libReactantExtra.${dlext}"
install_license ../../LICENSE
"""

# determine exactly which tarballs we should build
builds = []

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# Don't even bother with powerpc
platforms = filter(platforms) do p
    !( (arch(p) == "powerpc64le") )
end

# 64-bit or bust (for xla runtime executable)
platforms = filter(p -> arch(p) != "i686", platforms)

# No riscv for now
platforms = filter(p -> arch(p) != "riscv64", platforms)

# linux aarch has onednn issues
# platforms = filter(p -> !(arch(p) == "aarch64" && Sys.islinux(p)), platforms)
platforms = filter(p -> !(arch(p) == "armv6l" && Sys.islinux(p)), platforms)
platforms = filter(p -> !(arch(p) == "armv7l" && Sys.islinux(p)), platforms)

# TSL exec info rewriting needed
# external/tsl/tsl/platform/default/stacktrace.h:29:10: fatal error: execinfo.h: No such file or directory
# [01:23:40]    29 | #include <execinfo.h>
platforms = filter(p -> !(libc(p) == "musl"), platforms)

# NSync is picking up wrong stuff for cross compile, to deal with later
# 02] ./external/nsync//platform/c++11.futex/platform.h:24:10: fatal error: 'linux/futex.h' file not found
# [00:20:02] #include <linux/futex.h>
platforms = filter(p -> !(Sys.isfreebsd(p)), platforms)

# platforms = filter(p -> (Sys.isapple(p)), platforms)
# platforms = filter(p -> arch(p) != "x86_64", platforms)

# platforms = filter(p -> (Sys.isapple(p)), platforms)

# platforms = filter(p -> !(Sys.isapple(p)), platforms)
# platforms = filter(p -> arch(p) == "x86_64", platforms)

# Julia builds with libstdc++ C++03 string ABI are somewhat niche, ignore them
platforms = filter(p -> cxxstring_abi(p) != "cxx03", platforms)

augment_platform_block="""
    $(read(joinpath(@__DIR__, "platform_augmentation.jl"), String))
    """

# for gpu in ("none", "cuda", "rocm"), mode in ("opt", "dbg"), platform in platforms
for gpu in ("none", "cuda", "rocm"), mode in ("opt", "dbg"), cuda_version in ("none", "12.6", "12.8", "13.0"), rocm_version in ("none", "7.0",), platform in platforms

    gpu != "rocm" && continue
    
    augmented_platform = deepcopy(platform)
    augmented_platform["mode"] = mode
    augmented_platform["gpu"] = gpu
    
    gpu_version = "none"
    if gpu == "none"
	 if cuda_version != "none"
	     continue
	 end
	 if rocm_version != "none"
	     continue
	 end
    elseif gpu == "rocm"
	 if cuda_version != "none"
	     continue
	 end
	 if rocm_version == "none"
	     continue
	 end
	gpu_version = rocm_version
    else 
	 @assert gpu == "cuda"
	 if cuda_version == "none"
	     continue
	 end
	 if rocm_version != "none"
	     continue
	 end
	gpu_version = rocm_version
    end
    augmented_platform["gpu_version"] = gpu_version
    dependencies = []

    preferred_gcc_version = v"13"
    preferred_llvm_version = v"18.1.7"

    # Disable debug builds for cuda
    if mode == "dbg"
  	  if gpu != "none"
        continue
		  end
	    if !Sys.isapple(platform)
		    continue
		  end
    end

    # If you skip GPU builds here, remember to update also platform augmentation above.
    if gpu != "none" && Sys.isapple(platform)
        continue
    end

    # If you skip GPU builds here, remember to update also platform augmentation above.
    if gpu != "none" && Sys.iswindows(platform)
        continue
    end

    if gpu == "cuda" && arch(platform) == "aarch64" && VersionNumber(cuda_version) < v"12.4"
        # At the moment we can't build for CUDA 12.1 on aarch64, let's skip it
        continue
    end
    
    if gpu == "rocm" && arch(platform) == "aarch64"
        # At the moment we can't build for ROCM on aarch64, let's skip it
        continue
    end

    hermetic_cuda_version_map = Dict(
        # Our platform tags use X.Y version scheme, but for some CUDA versions we need to
        # pass Bazel a full version number X.Y.Z.  See `CUDA_REDIST_JSON_DICT` in
        # <https://github.com/openxla/xla/blob/main/third_party/tsl/third_party/gpus/cuda/hermetic/cuda_redist_versions.bzl>.
        "none" => "none",
        "11.8" => "11.8",
        "12.1" => "12.1.1",
        "12.2" => "12.2.0",
        "12.3" => "12.3.1",
        "12.4" => "12.4.1",
        "12.6" => "12.6.3",
        "12.8" => "12.8.1",
	"13.0" => "13.0.0"
    )
    
    hermetic_rocm_version_map = Dict(
        # Our platform tags use X.Y version scheme, but for some CUDA versions we need to
        # pass Bazel a full version number X.Y.Z.  See `CUDA_REDIST_JSON_DICT` in
        # <https://github.com/openxla/xla/blob/main/third_party/tsl/third_party/gpus/cuda/hermetic/cuda_redist_versions.bzl>.
        "none" => "none",
        "6.4" => "6.4.1",
        "6.5" => "6.5.1",
        "7.0" => "7.0.0",
    )


    prefix="""
    MODE=$(mode)
    HERMETIC_CUDA_VERSION=$(hermetic_cuda_version_map[cuda_version])
    # Don't use ccache on Yggdrasil, doesn't seem to work.
    USE_CCACHE=$(!BinaryBuilder.is_yggdrasil())
    HERMETIC_ROCM_VERSION=$(hermetic_rocm_version_map[rocm_version])
    """
    platform_sources = BinaryBuilder.AbstractSource[sources...]
    if Sys.isapple(platform)
        push!(platform_sources,
              ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz",
                            "cd4f08a75577145b8f05245a2975f7c81401d75e9535dcffbb879ee1deefcbf4"))
    end

    if arch(platform) == "aarch64" && gpu == "cuda"
        if hermetic_cuda_version_map[cuda_version] == "13.0.0"
	    # bazel currentlty tries to run  external/cuda_nvcc/bin/../nvvm/bin/cicc: line 1: ELF
	     continue

            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_13.0.0.json
	    push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-sbsa/cuda_nvcc-linux-sbsa-13.0.48-archive.tar.xz",
				"3146cee5148535cb06ea5727b6cc1b0d97a85838d1d98514dc6a589ca38e1495"),
		  )
	elseif hermetic_cuda_version_map[cuda_version] == "12.8.1"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.8.1.json
	    push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-sbsa/cuda_nvcc-linux-sbsa-12.8.93-archive.tar.xz",
				"dc0b713ce69fd921aa53ac68610717d126fc273a3c554b0465cf44d7e379f467"),
		  )
        elseif hermetic_cuda_version_map[cuda_version] == "12.6.3"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.6.3.json
	    push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-sbsa/cuda_nvcc-linux-sbsa-12.6.85-archive.tar.xz",
                                "1b834df41cb071884f33b1e4ffc185e4799975057baca57d80ba7c4591e67950"),
                  )
        elseif hermetic_cuda_version_map[cuda_version] == "12.3.1"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.3.1.json
	    push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-sbsa/cuda_nvcc-linux-sbsa-12.3.103-archive.tar.xz",
                                "1bb1faac058a1e122adad09dabaa378ee9591762b7787a9144de845f99e03aed"),
                  )
        elseif hermetic_cuda_version_map[cuda_version] == "12.4.1"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.4.1.json
	    push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-sbsa/cuda_nvcc-linux-sbsa-12.4.131-archive.tar.xz",
                                "83f130dab0325e12b90fdf1279c0cbbd88acf638ef0a7e0cad72d50855a4f44a"),
                  )
        elseif hermetic_cuda_version_map[cuda_version] == "12.1.1"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.1.1.json
	    push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-sbsa/cuda_nvcc-linux-sbsa-12.1.105-archive.tar.xz",
                                "6e795ec791241e9320ec300657408cbfafbe7e79ceda0da46522cc85ced358f4"),
                  )
        end
        push!(dependencies,
              # Build dependency because we statically link libc++
              BuildDependency(PackageSpec("LLVMLibcxx_jll", preferred_llvm_version)),
              )
    end
	if gpu == "rocm"
		push!(dependencies, HostBuildDependency(PackageSpec("CMake_jll", v"3.30.2")))

		push!(platform_sources, 
		    FileSource("https://repo.anaconda.com/miniconda/Miniconda3-py311_24.3.0-0-Linux-x86_64.sh",
			       "4da8dde69eca0d9bc31420349a204851bfa2a1c87aeb87fe0c05517797edaac4", "miniconda.sh"))

	      if rocm_version == "6.4"
	       push!(platform_sources,
                  ArchiveSource("https://github.com/ROCm/TheRock/releases/download/nightly-tarball/therock-dist-linux-gfx94X-dcgpu-6.4.0rc20250520.tar.gz",
				"b3d64777a79f33e8d1b50230f26ac769bd77d5bc11bd850ec111933c842914e9")
                  )
	       elseif rocm_version == "6.5"
	       push!(platform_sources,
                  ArchiveSource("https://github.com/ROCm/TheRock/releases/download/nightly-tarball/therock-dist-linux-gfx94X-dcgpu-6.5.0rc20250610.tar.gz",
				"113e44dcd7868ffab92193bbcb8653a374494f0c5b393545f08551ea835a1ee5")
                  )
	       elseif rocm_version == "7.0"
	       push!(platform_sources,
                  ArchiveSource("https://github.com/ROCm/TheRock/releases/download/nightly-tarball/therock-dist-linux-gfx110X-dgpu-7.0.0rc20250714.tar.gz",
				"8c64dd2045736a18322756c52dccf11370e9efd04d29dd58f156491b27156e3c")
                  )
	       end
	end

    should_build_platform(triplet(augmented_platform)) || continue
	
    # The products that we will ensure are always built
    products = Product[
        LibraryProduct(["libReactantExtra", "libReactantExtra"], :libReactantExtra)
    ]
	
    if gpu == "cuda"
    	for lib in (
		"libnccl",
		"libcufft",
		"libcudnn_engines_precompiled",
		"libcudart",
		"libcublasLt",
		"libcudnn_heuristic",
		"libcudnn_cnn",
		"libnvrtc",
		"libcudnn_adv",
		"libcudnn",
		"libnvJitLink",
		"libcublas",
		"libcudnn_ops",
		"libnvrtc-builtins",
		"libcudnn_graph",
		"libcusolver",
		# "libcuda",
		"libcudnn_engines_runtime_compiled",
		"libcusparse",
		"libnvshmem_host",
		"nvshmem_bootstrap_uid",
		"nvshmem_transport_ibrc"
	)
	    san = replace(lib, "-" => "_")
	    push!(products,
                  LibraryProduct([lib, lib], Symbol(san);
                                 dont_dlopen=true, dlopen_flags=[:RTLD_LOCAL]))
	end
	push!(products, ExecutableProduct(["ptxas"], :ptxas, "lib/cuda/bin"))
	push!(products, ExecutableProduct(["fatbinary"], :fatbinary, "lib/cuda/bin"))
	push!(products, FileProduct("lib/cuda/nvvm/libdevice/libdevice.10.bc", :libdevice))
	push!(products, FileProduct("lib/libnvshmem_device.bc", :libnvshmem_device))
    end
    
    if gpu == "rocm"
    	for lib in (
		"libamd_comgr",
		"libamdhip64",
		"libhipfft",
		"libhipsolver",
		"libhipsolver_fortran",
		"libhsa-runtime64",
		"librccl",
		"librocm_smi64",
		"librocprofiler-register",
		"librocsolver",
	)
	    san = replace(lib, "-" => "_")
	    push!(products,
                  LibraryProduct([lib, lib], Symbol(san);
                                 dont_dlopen=true, dlopen_flags=[:RTLD_LOCAL]))
	end
    end

    push!(builds, (;
                   dependencies, products, sources=platform_sources,
                   platforms=[augmented_platform], script=prefix*script, preferred_gcc_version, preferred_llvm_version
    ))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, build.script,
                   build.platforms, build.products, build.dependencies;
                   preferred_gcc_version=build.preferred_gcc_version, build.preferred_llvm_version, julia_compat="1.10",
		   compression_format="xz",
                   # We use GCC 13, so we can't dlopen the library during audit
                   augment_platform_block, lazy_artifacts=true, lock_microarchitecture=false, dont_dlopen=true)
end
