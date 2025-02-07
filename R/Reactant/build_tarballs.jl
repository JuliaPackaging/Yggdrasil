using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "Reactant"
repo = "https://github.com/EnzymeAD/Reactant.jl.git"
version = v"0.0.63"

sources = [
  GitSource(repo, "4378d3e28347eb9ed76134aaa0826b2d2e8a2062"),
  FileSource("https://github.com/wsmoses/binaries/releases/download/v0.0.1/bazel-dev",
             "8b43ffdf519848d89d1c0574d38339dcb326b0a1f4015fceaa43d25107c3aade")
]


# Bash recipe for building across all platforms
script = raw"""
cd Reactant.jl/deps/ReactantExtra

echo Clang version: $(clang --version)
echo GCC version: $(gcc --version)

GCC_VERSION=$(gcc --version | head -1 | awk '{ print $3 }')
GCC_MAJOR_VERSION=$(echo "${GCC_VERSION}" | cut -d. -f1)

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Compiling LLVM components within XLA requires macOS SDK 10.14.
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi

apk add openjdk11-jdk
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")

mkdir -p .local/bin
export LOCAL="`pwd`/.local/bin"
export PATH="$LOCAL:$PATH"

export BAZEL=$WORKSPACE/srcdir/bazel-dev
chmod +x $BAZEL

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

# # Use ccache to speedup re-builds
# BAZEL_BUILD_FLAGS+=(--action_env=USE_CCACHE=${USE_CCACHE} --action_env=CCACHE_DIR=/root/.ccache)
# BAZEL_BUILD_FLAGS+=(--action_env=CCACHE_NOHASHDIR=yes)
# # Set `SUPER_VERBOSE` to a non empty string to make the compiler wrappers more
# # verbose. Useful for debugging.
# BAZEL_BUILD_FLAGS+=(--action_env=SUPER_VERBOSE=true)

BAZEL_BUILD_FLAGS+=(--verbose_failures)
BAZEL_BUILD_FLAGS+=(--cxxopt=-std=c++17 --host_cxxopt=-std=c++17)
BAZEL_BUILD_FLAGS+=(--cxxopt=-DTCP_USER_TIMEOUT=0)
BAZEL_BUILD_FLAGS+=(--check_visibility=false)
BAZEL_BUILD_FLAGS+=(--build_tag_filters=-jlrule)
BAZEL_BUILD_FLAGS+=(--experimental_cc_shared_library)

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
fi

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

    if [[ "${target}" == x86_64* ]]; then
        BAZEL_BUILD_FLAGS+=(--platforms=@//:darwin_x86_64)
        BAZEL_BUILD_FLAGS+=(--cpu=${BAZEL_CPU})
    elif [[ "${target}" == aarch64-* ]]; then
        BAZEL_BUILD_FLAGS+=(--platforms=@//:darwin_arm64)
        BAZEL_BUILD_FLAGS+=(--cpu=${BAZEL_CPU})
    fi
    BAZEL_BUILD_FLAGS+=(--linkopt=-twolevel_namespace)
    # BAZEL_BUILD_FLAGS+=(--crosstool_top=@xla//tools/toolchains/cross_compile/cc:cross_compile_toolchain_suite)
    BAZEL_BUILD_FLAGS+=(--define=clang_macos_x86_64=true)
    BAZEL_BUILD_FLAGS+=(--define HAVE_LINK_H=0)
    export MACOSX_DEPLOYMENT_TARGET=10.14
    BAZEL_BUILD_FLAGS+=(--macos_minimum_os=${MACOSX_DEPLOYMENT_TARGET})
    BAZEL_BUILD_FLAGS+=(--action_env=MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET})
    BAZEL_BUILD_FLAGS+=(--host_action_env=MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET})
    BAZEL_BUILD_FLAGS+=(--repo_env=MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET})
    BAZEL_BUILD_FLAGS+=(--test_env=MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET})
    BAZEL_BUILD_FLAGS+=(--incompatible_remove_legacy_whole_archive)
    BAZEL_BUILD_FLAGS+=(--nolegacy_whole_archive)
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
    elif [[ "${target}" == aarch64-* ]]; then
        BAZEL_BUILD_FLAGS+=(--crosstool_top=@//:ygg_cross_compile_toolchain_suite)
        BAZEL_BUILD_FLAGS+=(--platforms=@//:linux_aarch64)
        BAZEL_BUILD_FLAGS+=(--cpu=${BAZEL_CPU})
        BAZEL_BUILD_FLAGS+=(--@xla//xla/tsl/framework/contraction:disable_onednn_contraction_kernel=True)
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
            --action_env=CLANG_CUDA_COMPILER_PATH=$(which clang)
            --repo_env=CUDA_REDIST_TARGET_PLATFORM="aarch64"
            --linkopt="-L${prefix}/libcxx/lib"
        )
    fi

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

    sed -i.bak1 -e "s/\\"k8|/\\"${BAZEL_CPU}\\": \\":cc-compiler-k8\\", \\"k8|/g" \
                -e "s/cpu = \\"k8\\"/cpu = \\"${BAZEL_CPU}\\"/g" \
                /workspace/bazel_root/*/external/local_config_cc/BUILD

    cat /workspace/bazel_root/*/external/local_config_cc/BUILD

    # We expect the following bazel build command to fail to link at the end, because the
    # build system insists on linking with `-whole_archive` also on macOS.  Until we figure
    # out how to make it stop doing this we have to manually do this.  Any other error
    # before the final linking stage is unexpected and will have to be dealt with.
    $BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so || echo "Bazel build failed, proceed to manual linking, check if there are are non-linking errors"

    # Manually remove `whole-archive` directive for the linker
    sed -i.bak1 -e "/whole-archive/d" \
                -e "/lrt/d" \
                bazel-bin/libReactantExtra.so-2.params

    # # Show the params file for debugging, but convert newlines to spaces
    # cat bazel-bin/libReactantExtra.so-2.params | tr '\n' ' '
    # echo ""

    cc @bazel-bin/libReactantExtra.so-2.params
else
    $BAZEL ${BAZEL_FLAGS[@]} build --repo_env=CC ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so
fi

rm -f bazel-bin/libReactantExtraLib*
rm -f bazel-bin/libReactant*params
mkdir -p ${libdir}

if [[ "${bb_full_target}" == *gpu+cuda* ]]; then
    rm -rf bazel-bin/_solib_local/*stub*/*so*
    cp -v bazel-bin/_solib_local/*/*so* ${libdir}

    if [[ "${target}" == x86_64-linux-gnu ]]; then
        NVCC_DIR=(bazel-bin/libReactantExtra.so.runfiles/cuda_nvcc)
    else
        NVCC_DIR=(/workspace/srcdir/cuda_nvcc-*-archive)
    fi
    install -Dvm 644 "${NVCC_DIR[@]}/nvvm/libdevice/libdevice.10.bc" -t "${libdir}/cuda/nvvm/libdevice"
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

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libReactantExtra", "libReactantExtra"], :libReactantExtra), #; dlopen_flags=[:RTLD_NOW,:RTLD_DEEPBIND]),
]

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

# Windows has a cuda configure issue, to investigate either fixing/disabling cuda
platforms = filter(p -> !(Sys.iswindows(p)), platforms)

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
for gpu in ("none", "cuda"), mode in ("opt", "dbg"), cuda_version in ("none", "12.1", "12.4", "12.6"), platform in platforms

    augmented_platform = deepcopy(platform)
    augmented_platform["mode"] = mode
    augmented_platform["gpu"] = gpu
    augmented_platform["cuda_version"] = cuda_version
    dependencies = []

    preferred_gcc_version = v"13"
    preferred_llvm_version = v"18.1.7"

    if mode == "dbg" && !Sys.isapple(platform)
        continue
    end

    if !((gpu == "cuda") ⊻ (cuda_version == "none"))
        continue
    end

    # If you skip GPU builds here, remember to update also platform augmentation above.
    if gpu != "none" && Sys.isapple(platform)
        continue
    end

    if gpu == "cuda" && arch(platform) == "aarch64" && VersionNumber(cuda_version) < v"12.4"
        # At the moment we can't build for CUDA 12.1 on aarch64, let's skip it
        continue
    end

    hermetic_cuda_version_map = Dict(
        # Our platform tags use X.Y version scheme, but for some CUDA versions we need to
        # pass Bazel a full version number X.Y.Z.  See `CUDA_REDIST_JSON_DICT` in
        # <https://github.com/openxla/xla/blob/main/third_party/tsl/third_party/gpus/cuda/hermetic/cuda_redist_versions.bzl>.
        "none" => "none",
        "11.8" => "11.8",
        "12.1" => "12.1.1",
        "12.3" => "12.3.1",
        "12.4" => "12.4.1",
        "12.6" => "12.6.3",
    )

    prefix="""
    MODE=$(mode)
    HERMETIC_CUDA_VERSION=$(hermetic_cuda_version_map[cuda_version])
    """
    platform_sources = BinaryBuilder.AbstractSource[sources...]
    if Sys.isapple(platform) && arch(platform) == "x86_64"
        push!(platform_sources,
              ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                            "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"))
    end

    if !Sys.isapple(platform)
      push!(dependencies, Dependency(PackageSpec(; name="CUDA_Driver_jll")))
    end

    if arch(platform) == "aarch64" && gpu == "cuda"
        if hermetic_cuda_version_map[cuda_version] == "12.6.3"
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

    should_build_platform(triplet(augmented_platform)) || continue
    products2 = copy(products)
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
	)
	    san = replace(lib, "-" => "_")
	    push!(products2,
                  LibraryProduct([lib, lib], Symbol(san);
                                 dont_dlopen=true, dlopen_flags=[:RTLD_LOCAL]))
	end
	push!(products2, ExecutableProduct(["ptxas"], :ptxas, "lib/cuda/bin"))
	push!(products2, ExecutableProduct(["fatbinary"], :fatbinary, "lib/cuda/bin"))
	push!(products2, FileProduct("lib/cuda/nvvm/libdevice/libdevice.10.bc", :libdevice))

        if VersionNumber(cuda_version) < v"12.6"
            # For older versions of CUDA we need to use GCC 12:
            # <https://forums.developer.nvidia.com/t/strange-errors-after-system-gcc-upgraded-to-13-1-1/252441>.
            preferred_gcc_version = v"12"
        end
        if VersionNumber(cuda_version) < v"12"
            # For older versions of CUDA we need to use GCC 11:
            # <https://stackoverflow.com/questions/72348456/error-when-compiling-a-cuda-program-invalid-type-argument-of-unary-have-i>.
            preferred_gcc_version = v"11"
        end
    end

    push!(builds, (;
                   dependencies, products=products2, sources=platform_sources,
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
                   # We use GCC 13, so we can't dlopen the library during audit
                   augment_platform_block, lazy_artifacts=true, lock_microarchitecture=false, dont_dlopen=true)
end
