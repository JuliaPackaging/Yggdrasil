using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "Reactant"
repo = "https://github.com/EnzymeAD/Reactant.jl.git"
version = v"0.0.29"

sources = [
  GitSource(repo, "5b874216c3c328fa1fdbde273fdeb3a6156b5da3"),
  FileSource("https://github.com/wsmoses/binaries/releases/download/v0.0.1/bazel-dev",
             "8b43ffdf519848d89d1c0574d38339dcb326b0a1f4015fceaa43d25107c3aade")
]


# Bash recipe for building across all platforms
script = raw"""
cd Reactant.jl/deps/ReactantExtra

echo Clang version: $(clang --version)
echo GCC version: $(gcc --version)

if [[ "${bb_full_target}" == x86_64-apple-darwin* ]]; then
    # LLVM requires macOS SDK 10.14.
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

env

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

BAZEL_BUILD_FLAGS+=(--verbose_failures)
BAZEL_BUILD_FLAGS+=(--cxxopt=-std=c++17 --host_cxxopt=-std=c++17)
BAZEL_BUILD_FLAGS+=(--cxxopt=-DTCP_USER_TIMEOUT=0)
BAZEL_BUILD_FLAGS+=(--check_visibility=false)
BAZEL_BUILD_FLAGS+=(--build_tag_filters=-jlrule)
BAZEL_BUILD_FLAGS+=(--experimental_cc_shared_library)

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

if [[ "${bb_full_target}" == *darwin* ]]; then
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
    
    pushd $WORKSPACE/srcdir/llvm*
	mkdir build
	cd build
	cmake ../llvm -DLLVM_ENABLE_PROJECTS="lld" -DCMAKE_BUILD_TYPE=Release -DCMAKE_CROSSCOMPILING=False -DLLVM_TARGETS_TO_BUILD="X86;AArch64" -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} -GNinja -DCMAKE_EXE_LINKER_FLAGS="-static"
	ninja lld
	export LLD2=`pwd`/bin/ld64.lld
	popd

    if [[ "${bb_full_target}" == *86* ]]; then
        BAZEL_BUILD_FLAGS+=(--platforms=@//:darwin_x86_64)
    else
        BAZEL_BUILD_FLAGS+=(--platforms=@//:darwin_arm64)
        sed -i '/gcc-install-dir/d'  "/opt/bin/x86_64-linux-musl-cxx11/x86_64-linux-musl-clang"
        sed -i '/gcc-install-dir/d'  "/opt/bin/x86_64-linux-musl-cxx11/x86_64-linux-musl-clang++"
        BAZEL_BUILD_FLAGS+=(--cpu=darwin_arm64)
    fi
    BAZEL_BUILD_FLAGS+=(--linkopt=-fuse-ld=lld)
    BAZEL_BUILD_FLAGS+=(--linkopt=-twolevel_namespace)
    # BAZEL_BUILD_FLAGS+=(--crosstool_top=@xla//tools/toolchains/cross_compile/cc:cross_compile_toolchain_suite)
    BAZEL_BUILD_FLAGS+=(--define=clang_macos_x86_64=true)
    BAZEL_BUILD_FLAGS+=(--define HAVE_LINK_H=0)
    BAZEL_BUILD_FLAGS+=(--macos_minimum_os=10.14)
    export MACOSX_DEPLOYMENT_TARGET=10.14
    BAZEL_BUILD_FLAGS+=(--action_env=MACOSX_DEPLOYMENT_TARGET=10.14)
    BAZEL_BUILD_FLAGS+=(--host_action_env=MACOSX_DEPLOYMENT_TARGET=10.14)
    BAZEL_BUILD_FLAGS+=(--repo_env=MACOSX_DEPLOYMENT_TARGET=10.14)
    BAZEL_BUILD_FLAGS+=(--test_env=MACOSX_DEPLOYMENT_TARGET=10.14)
    BAZEL_BUILD_FLAGS+=(--incompatible_remove_legacy_whole_archive)
    BAZEL_BUILD_FLAGS+=(--nolegacy_whole_archive)
fi


if [[ "${bb_full_target}" == *linux* ]]; then
    sed -i "s/getopts \\"/getopts \\"p/g" /sbin/ldconfig
    mkdir -p .local/bin
    echo "#!/bin/sh" > .local/bin/ldconfig
    echo "" >> .local/bin/ldconfig
    chmod +x .local/bin/ldconfig
    export PATH="`pwd`/.local/bin:$PATH"
    BAZEL_BUILD_FLAGS+=(--copt=-Wno-error=cpp)

    if [[ "${bb_full_target}" == *86* ]]; then
        BAZEL_BUILD_FLAGS+=(--platforms=@//:linux_x86_64)
    else
        BAZEL_BUILD_FLAGS+=(--crosstool_top=@//:ygg_cross_compile_toolchain_suite)
        BAZEL_BUILD_FLAGS+=(--platforms=@//:linux_aarch64)
        BAZEL_BUILD_FLAGS+=(--cpu=aarch64)
        BAZEL_BUILD_FLAGS+=(--@xla//xla/tsl/framework/contraction:disable_onednn_contraction_kernel=True)
    fi
fi

if [[ "${bb_full_target}" == *aarch64* ]]; then
    BAZEL_BUILD_FLAGS+=(--copt=-D__ARM_FEATURE_AES=1)
    BAZEL_BUILD_FLAGS+=(--copt=-D__ARM_NEON=1)
    BAZEL_BUILD_FLAGS+=(--copt=-D__ARM_FEATURE_SHA2=1)
    BAZEL_BUILD_FLAGS+=(--copt=-DDNNL_ARCH_GENERIC=1)
    BAZEL_BUILD_FLAGS+=(--define=@xla//build_with_mkl_aarch64=true)
fi

if [[ "${bb_full_target}" == *cuda* ]]; then
    BAZEL_BUILD_FLAGS+=(--config=cuda)
fi

if [[ "${bb_full_target}" == *rocm* ]]; then
    BAZEL_BUILD_FLAGS+=(--config=rocm)
fi

if [[ "${bb_full_target}" == *freebsd* ]]; then
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_x86_32_1=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_x86_64_1=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_x86_64_2=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_aarch64=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_ppc64=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_s390x=false)
    BAZEL_BUILD_FLAGS+=(--define=freebsd=true)
    BAZEL_BUILD_FLAGS+=(--cpu=freebsd)
fi

if [[ "${bb_full_target}" == *i686* ]]; then
    BAZEL_BUILD_FLAGS+=(--define=build_with_mkl=false --define=enable_mkl=false)
fi

sed -i "s/BB_TARGET/${bb_target}/g" BUILD
sed -i "s/BB_FULL_TARGET/${bb_full_target}/g" BUILD

export HERMETIC_PYTHON_VERSION=3.12

$BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]}
sed -i "s/^cc_library(/cc_library(linkstatic=True,/g" /workspace/bazel_root/*/external/llvm-raw/utils/bazel/llvm-project-overlay/mlir/BUILD.bazel
if [[ "${bb_full_target}" == *darwin* ]]; then
    $BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so || echo stage1
    if [[ "${bb_full_target}" == *86* ]]; then
        echo "x86"
    else
        sed -i.bak1 "s/\\"k8|/\\"darwin_arm64\\": \\":cc-compiler-k8\\", \\"k8|/g" /workspace/bazel_root/*/external/local_config_cc/BUILD
        sed -i.bak1 "s/cpu = \\"k8\\"/cpu = \\"darwin_arm64\\"/g" /workspace/bazel_root/*/external/local_config_cc/BUILD
        cat /workspace/bazel_root/*/external/local_config_cc/BUILD
        $BAZEL ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so || echo stage2
    fi
	sed -i.bak1 "/whole-archive/d" bazel-bin/libReactantExtra.so-2.params
	sed -i.bak1 "/lrt/d" bazel-bin/libReactantExtra.so-2.params
    sed -i.bak0 "/lld/d" bazel-bin/libReactantExtra.so-2.params
	echo "-fuse-ld=lld" >> bazel-bin/libReactantExtra.so-2.params
	echo "--ld-path=$LLD2" >> bazel-bin/libReactantExtra.so-2.params
	cat bazel-bin/libReactantExtra.so-2.params
    cc @bazel-bin/libReactantExtra.so-2.params
else
    $BAZEL ${BAZEL_FLAGS[@]} build --repo_env=CC ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so
fi
rm -f bazel-bin/libReactantExtraLib*
rm -f bazel-bin/libReactant*params
mkdir -p ${libdir}

if [[ "${bb_full_target}" == *cuda* ]]; then
    rm -rf bazel-bin/_solib_local/*stub*/*so*
    cp -v bazel-bin/_solib_local/*/*so* ${libdir}
    mkdir -p ${libdir}/cuda/nvvm/libdevice
    mkdir -p ${libdir}/cuda/bin
    cp -v bazel-bin/libReactantExtra.so.runfiles/cuda_nvcc/nvvm/libdevice/libdevice.10.bc ${libdir}/cuda/nvvm/libdevice
    cp -v bazel-bin/libReactantExtra.so.runfiles/cuda_nvcc/bin/ptxas ${libdir}/cuda/bin
    cp -v bazel-bin/libReactantExtra.so.runfiles/cuda_nvcc/bin/fatbinary ${libdir}/cuda/bin
fi

cp -v bazel-bin/libReactantExtra.so ${libdir}
if [[ "${bb_full_target}" == *darwin* ]]; then
    mv ${libdir}/libReactantExtra.so ${libdir}/libReactantExtra.dylib
fi
if [[ "${bb_full_target}" == *mingw* ]]; then
    mv ${libdir}/libReactantExtra.so ${libdir}/libReactantExtra.dll
fi
cd ../..
install_license LICENSE
"""

# determine exactly which tarballs we should build
builds = []
    
# Dependencies that must be installed before this package can be built

dependencies = Dependency[]

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
# platforms = filter(p -> cxxstring_abi(p) == "cxx11", platforms)

augment_platform_block="""
    using Base.BinaryPlatforms
    using Libdl
    const Reactant_UUID = Base.UUID("0192cb87-2b54-54ad-80e0-3be72ad8a3c0")
    const preferences = Base.get_preferences(Reactant_UUID)
    Base.record_compiletime_preference(Reactant_UUID, "mode")
    Base.record_compiletime_preference(Reactant_UUID, "gpu")

    const mode_preference = if haskey(preferences, "mode")
        if isa(preferences["mode"], String) && preferences["mode"] in ["opt", "dbg"]
            preferences["mode"]
        else
            @error "Mode preference is not valid; expected 'opt' or 'dbg', but got '\$(preferences[\"debug\"])'"
            nothing
        end
    else
        nothing
    end
    
    const gpu_preference = if haskey(preferences, "gpu")
    if isa(preferences["gpu"], String) && preferences["gpu"] in ["none", "cuda", "rocm"]
            preferences["gpu"]
        else
            @error "GPU preference is not valid; expected 'none', 'cuda' or 'rocm', but got '\$(preferences[\"debug\"])'"
            nothing
        end
    else
        nothing
    end

    function augment_platform!(platform::Platform)

        mode = get(ENV, "REACTANT_MODE", something(mode_preference, "opt"))
        if !haskey(platform, "mode")
            platform["mode"] = mode
        end
        	
	gpu = something(gpu_preference, "none")

	cuname = if Sys.iswindows()
            Libdl.find_library("nvcuda")
        else
            Libdl.find_library(["libcuda.so.1", "libcuda.so"])
        end

        # if we've found a system driver, put a dependency on it,
        # so that we get recompiled if the driver changes.
        if cuname != "" && gpu == "none"
            handle = Libdl.dlopen(cuname)
            path = Libdl.dlpath(handle)
            Libdl.dlclose(handle)

            @debug "Adding include dependency on \$path"
            Base.include_dependency(path)
	    gpu = "cuda"
        end
	
	roname = ""
        # if we've found a system driver, put a dependency on it,
        # so that we get recompiled if the driver changes.
        if roname != "" && gpu == "none"
            handle = Libdl.dlopen(roname)
            path = Libdl.dlpath(handle)
            Libdl.dlclose(handle)

            @debug "Adding include dependency on \$path"
            Base.include_dependency(path)
	    gpu = "rocm"
        end

	gpu = get(ENV, "REACTANT_GPU", gpu)
        if !haskey(platform, "gpu")
	    platform["gpu"] = gpu
        end

        return platform
    end
    """

# for gpu in ("none", "cuda", "rocm"), mode in ("opt", "dbg"), platform in platforms
for gpu in ("none", "cuda"), mode in ("opt", "dbg"), platform in platforms
    augmented_platform = deepcopy(platform)
    augmented_platform["mode"] = mode
    augmented_platform["gpu"] = gpu
    cuda_deps = []

    if mode == "dbg" && !Sys.isapple(platform)
        continue
    end
    
    if gpu != "none" && Sys.isapple(platform)
        continue
    end
    
    # TODO temporarily disable aarch64-linux-gnu + cuda: we need to build it with clang
    if gpu != "none" && Sys.islinux(platform) && arch(platform) == "aarch64"
        continue
    end

    prefix="export MODE="*mode*"\n\n"
    platform_sources = BinaryBuilder.AbstractSource[sources...]
    if Sys.isapple(platform)
        push!(platform_sources,
              ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                            "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"))
	push!(platform_sources,
                  ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.4/llvm-project-18.1.4.src.tar.xz",
                                "2c01b2fbb06819a12a92056a7fd4edcdc385837942b5e5260b9c2c0baff5116b"))
    end

    if !Sys.isapple(platform)
      push!(cuda_deps, Dependency(PackageSpec(name="CUDA_Driver_jll")))
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
		push!(products2, LibraryProduct([lib, lib],
		Symbol(san); dont_dlopen=true, dlopen_flags=[:RTLD_LOCAL]))
	end
	push!(products2, ExecutableProduct(["ptxas"], :ptxas, "lib/cuda/bin"))
	push!(products2, ExecutableProduct(["fatbinary"], :fatbinary, "lib/cuda/bin"))
	push!(products2, FileProduct("lib/cuda/nvvm/libdevice/libdevice.10.bc", :libdevice))
    end

    push!(builds, (;
                   dependencies=[dependencies; cuda_deps], products=products2, sources=platform_sources,
        platforms=[augmented_platform], script=prefix*script
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
                   preferred_gcc_version=v"10", preferred_llvm_version=v"18", julia_compat="1.6",
                   augment_platform_block, lazy_artifacts=true)
end

