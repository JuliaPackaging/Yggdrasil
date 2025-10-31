using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "Reactant"
repo = "https://github.com/EnzymeAD/Reactant.jl.git"
reactant_commit = "54f83c1e9f11ba8236776b9de2443d382e9e8a66"
version = v"0.0.256"

sources = [
   GitSource(repo, reactant_commit),
   FileSource("https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.7%2B6/OpenJDK21U-jdk_x64_alpine-linux_hotspot_21.0.7_6.tar.gz", "79ecc4b213d21ae5c389bea13c6ed23ca4804a45b7b076983356c28105580013"),
   FileSource("https://github.com/JuliaBinaryWrappers/Bazel_jll.jl/releases/download/Bazel-v7.6.1+0/Bazel.v7.6.1.x86_64-linux-musl-cxx03.tar.gz", "01ac6c083551796f1f070b0dc9c46248e6c49e01e21040b0c158f6e613733345")
]

# When we run CI in Enzyme-JAX repository we need to be able to change the commit to check out.
enzyme_jax_commit = get(ENV, "ENZYME_JAX_COMMIT", "")

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir
tar xzf OpenJDK21U-jdk_x64_alpine-linux_hotspot_21.0.7_6.tar.gz
tar xzf Bazel.v7.6.1.x86_64-linux-musl-cxx03.tar.gz
export JAVA_HOME="${PWD}/jdk-21.0.7+6"
export BAZEL="${PWD}/bin/bazel"

cd Reactant.jl/deps/ReactantExtra

echo Clang version: $(clang --version)
echo GCC version: $(gcc --version)

GCC_VERSION=$(gcc --version | head -1 | awk '{ print $3 }')
GCC_MAJOR_VERSION=$(echo "${GCC_VERSION}" | cut -d. -f1)

# Change Enzyme-JAX commit, necessary in CI of that repository.
if [[ -n "${ENZYME_JAX_COMMIT}" ]]; then
   sed -i.bak 's/ENZYMEXLA_COMMIT = ".*"/ENZYMEXLA_COMMIT = "'${ENZYME_JAX_COMMIT}'"/' WORKSPACE
fi

if [[ "${target}" == *-apple-darwin* ]]; then
    # Compiling LLVM components within XLA requires macOS SDK 10.14
    # and then we use `std::reinterpret_pointer_cast` in ReactantExtra
    # which requires macOS SDK 11.3.
    # Install a newer SDK which supports C++20
    pushd $WORKSPACE/srcdir/MacOSX12.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    rm -rf /opt/${target}/${target}/sys-root/usr/*
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
    export MACOSX_DEPLOYMENT_TARGET=12.3
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
BAZEL_BUILD_FLAGS+=(--action_env=USE_CCACHE=${USE_CCACHE} --action_env=CCACHE_DIR=${CCACHE_DIR})
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
BAZEL_BUILD_FLAGS+=(--host_crosstool_top=@//:ygg_host_toolchain_suite)
    
# `using_clang` comes from Enzyme-JAX, to handle clang-specific options.
BAZEL_BUILD_FLAGS+=(--define=using_clang=true)

if [[ "${bb_full_target}" == *gpu+none* ]]; then
    BAZEL_BUILD_FLAGS+=(--crosstool_top=@//:ygg_cross_compile_toolchain_suite)
fi

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
	BAZEL_BUILD_FLAGS+=(--config=macos)
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
    BAZEL_BUILD_FLAGS+=(--define=clang_macos_x86_64=true)
    BAZEL_BUILD_FLAGS+=(--define HAVE_LINK_H=0)
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
    BAZEL_BUILD_FLAGS+=(--copt=-DPTHREADPOOL_USE_PTHREADS=1)
    BAZEL_BUILD_FLAGS+=(--copt=-DWIN32_LEAN_AND_MEAN)
    BAZEL_BUILD_FLAGS+=(--copt=-DNOGDI)
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
    BAZEL_BUILD_FLAGS+=(--repo_env=HERMETIC_CUDA_VERSION="${HERMETIC_CUDA_VERSION}")
    if [[ "${HERMETIC_CUDA_VERSION}" == *13.* ]]; then
    	BAZEL_BUILD_FLAGS+=(--config=cuda13)
    else
    	BAZEL_BUILD_FLAGS+=(--config=cuda12)
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
    )
fi

if [[ "${bb_full_target}" == *gpu+rocm* ]]; then
    BAZEL_BUILD_FLAGS+=(--config=rocm)
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

    # We expect the following bazel build command to fail to link at the end, because the
    # build system insists on linking with `-whole_archive` also on macOS.  Until we figure
    # out how to make it stop doing this we have to manually do this.  Any other error
    # before the final linking stage is unexpected and will have to be dealt with.
    $BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so || echo "Bazel build failed, proceed to manual linking, check if there are are non-linking errors"

    # Manually remove `whole-archive` directive for the linker
    sed -i.bak1 -e "/whole-archive/d" \
                -e "/gc-sections/d" \
                bazel-bin/libReactantExtra.so-2.params

    cc @bazel-bin/libReactantExtra.so-2.params
elif [[ "${target}" == *mingw32* ]]; then
    $BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so || echo stage1
    sed -i.bak1 -e "s/PTHREADPOOL_WEAK//g" /workspace/bazel_root/*/external/pthreadpool/src/portable-api.c
    $BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so || echo stage2
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
elif [[ "${target}" == aarch64-* ]] && [[ "${HERMETIC_CUDA_VERSION}" == *13.* ]]; then
    $BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so || echo stage1
    cp /workspace/srcdir/libnvvm-linux-x86_64-*/nvvm/bin/cicc /workspace/bazel_root/*/external/cuda_nvvm/nvvm/bin/cicc
    $BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so
elif [[ "${target}" == aarch64-* ]] && [[ "${HERMETIC_CUDA_VERSION}" == *12.* ]]; then
    $BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so || echo stage1
    cp /workspace/srcdir/cuda_nvcc-linux-sbsa*-archive/lib/*.a /workspace/bazel_root/*/external/cuda_nvcc/lib/
    $BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so
else
    $BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so
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

    # if [[ "${target}" == x86_64-linux-gnu ]] || [[ "${HERMETIC_CUDA_VERSION}" == *13.* ]]; then
    if [[ "${target}" == x86_64-linux-gnu ]]; then
        NVCC_DIR=(bazel-bin/libReactantExtra.so.runfiles/cuda_nvcc)
    else
        NVCC_DIR=(/workspace/srcdir/cuda_nvcc-linux-sbsa*-archive)
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
for gpu in ("none", "cuda"), mode in ("opt", "dbg"), cuda_version in ("none", "12.9", "13.0"), platform in platforms

    augmented_platform = deepcopy(platform)
    augmented_platform["mode"] = mode
    augmented_platform["gpu"] = gpu
    augmented_platform["cuda_version"] = cuda_version
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

    if !((gpu == "cuda") ⊻ (cuda_version == "none"))
        continue
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

    # When we're running CI for Enzyme-JAX, only build few platforms
    if !isempty(enzyme_jax_commit)
        if !((Sys.islinux(platform) && gpu == "cuda") || (Sys.isapple(platform) && mode == "opt") || (Sys.iswindows(platform)))
            continue
        end
    end

    hermetic_cuda_version_map = Dict(
        # Our platform tags use X.Y version scheme, but for some CUDA versions we need to
        # pass Bazel a full version number X.Y.Z.  See `CUDA_REDIST_JSON_DICT` in
        # <https://github.com/google-ml-infra/rules_ml_toolchain/blob/main/third_party/gpus/cuda/hermetic/cuda_redist_versions.bzl>.
        "none" => "none",
        "11.8" => "11.8",
        "12.1" => "12.1.1",
        "12.2" => "12.2.0",
        "12.3" => "12.3.1",
        "12.4" => "12.4.1",
        "12.6" => "12.6.3",
        "12.8" => "12.8.1",
        "12.9" => "12.9.1",
        "13.0" => "13.0.1"
    )

    prefix="""
    MODE=$(mode)
    HERMETIC_CUDA_VERSION=$(hermetic_cuda_version_map[cuda_version])
    # Don't use ccache on Yggdrasil, doesn't seem to work.
    USE_CCACHE=$(!BinaryBuilder.is_yggdrasil())
    ENZYME_JAX_COMMIT=$(enzyme_jax_commit)
    """
    platform_sources = BinaryBuilder.AbstractSource[sources...]
    if Sys.isapple(platform)
        push!(platform_sources,
    ArchiveSource("https://github.com/realjf/MacOSX-SDKs/releases/download/v0.0.1/MacOSX12.3.sdk.tar.xz",
		  "a511c1cf1ebfe6fe3b8ec005374b9c05e89ac28b3d4eb468873f59800c02b030"))
    end

    if arch(platform) == "aarch64" && gpu == "cuda"
        if hermetic_cuda_version_map[cuda_version] == "13.0.1"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_13.0.0.json
            push!(platform_sources,
		  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/libnvvm/linux-x86_64/libnvvm-linux-x86_64-13.0.88-archive.tar.xz",
				"17ef1665b63670887eeba7d908da5669fa8c66bb73b5b4c1367f49929c086353"),
		  )
	    push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-sbsa/cuda_nvcc-linux-sbsa-13.0.88-archive.tar.xz",
                                "01b01e10aa2662ad1b3aeab3317151d7d6d4a650eeade55ded504f6b7fced18e"),
                  )
	elseif hermetic_cuda_version_map[cuda_version] == "13.0.0"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_13.0.0.json
            push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-sbsa/cuda_nvcc-linux-sbsa-13.0.48-archive.tar.xz",
                                "3146cee5148535cb06ea5727b6cc1b0d97a85838d1d98514dc6a589ca38e1495"),
                  )
        elseif hermetic_cuda_version_map[cuda_version] == "12.9.1"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.8.1.json
            push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-sbsa/cuda_nvcc-linux-sbsa-12.9.86-archive.tar.xz",
                                "0aa1fce92dbae76c059c27eefb9d0ffb58e1291151e44ff7c7f1fc2dd9376c0d"),
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
              BuildDependency(PackageSpec(; name="LLVMLibcxx_jll", version=string(preferred_llvm_version))),
              )
    end

    should_build_platform(triplet(augmented_platform)) || continue

    # The products that we will ensure are always built
    products = Product[
        LibraryProduct(["libReactantExtra", "libReactantExtra"], :libReactantExtra)
    ]

    if gpu == "cuda"
	libs = String[
                "libnccl",
                # "libcuda",
                "libnvshmem_host",
                "nvshmem_bootstrap_uid",
                "nvshmem_transport_ibrc"
	]
	cudnn = true
	nvrtc = true
	others = VersionNumber(cuda_version) >= v"13"
	if cudnn
        append!(libs, String[
                "libcudnn_engines_precompiled",
                "libcudnn_heuristic",
                "libcudnn_cnn",
                "libcudnn_adv",
                "libcudnn",
                "libcudnn_ops",
                "libcudnn_graph",
                "libcudnn_engines_runtime_compiled",
		])
	end
	if nvrtc
        append!(libs, String[
                "libnvrtc",
                "libnvrtc-builtins",
		])
	end
	if others
            append!(libs, String[
				"libcufft",
                "libnvJitLink",
                "libcudart",
                "libcublasLt",
                "libcublas",
                "libcusolver",
                "libcusparse",
		]
		)
	end
        for lib in libs
            san = replace(lib, "-" => "_")
            push!(products,
                  LibraryProduct([lib, lib], Symbol(san);
                                 dont_dlopen=true, dlopen_flags=[:RTLD_LOCAL]))
        end
        push!(products, ExecutableProduct(["ptxas"], :ptxas, "lib/cuda/bin"))
        push!(products, ExecutableProduct(["fatbinary"], :fatbinary, "lib/cuda/bin"))
        push!(products, FileProduct("lib/cuda/nvvm/libdevice/libdevice.10.bc", :libdevice))
        push!(products, FileProduct("lib/libnvshmem_device.bc", :libnvshmem_device))

        if VersionNumber(cuda_version) < v"12.6"
            # For older versions of CUDA we need to use GCC 12:
            # <https://forums.developer.nvidia.com/t/strange-errors-after-system-gcc-upgraded-to-13-1-1/252441>.
            preferred_gcc_version = v"12"
        end
        # if VersionNumber(cuda_version) < v"12"
        #     # For older versions of CUDA we need to use GCC 11:
        #     # <https://stackoverflow.com/questions/72348456/error-when-compiling-a-cuda-program-invalid-type-argument-of-unary-have-i>.
        #     preferred_gcc_version = v"11"
        # end
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
                   augment_platform_block, lazy_artifacts=true, lock_microarchitecture=false, dont_dlopen=true,
                   # When we're running CI for Enzyme-JAX (i.e. when the commit is
                   # non-empty), don't run the audit to save time, we don't need it.
                   skip_audit=!isempty(enzyme_jax_commit),
                   )
end
