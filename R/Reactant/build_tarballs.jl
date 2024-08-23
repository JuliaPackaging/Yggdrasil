using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "Reactant"
repo = "https://github.com/EnzymeAD/Reactant.jl.git"
version = v"0.0.16"

sources = [
   GitSource(repo, "a32bef2e09537dd296c643156ab2c35382d9b1f2"),
]

# Bash recipe for building across all platforms
script = raw"""

cd Reactant.jl/deps/ReactantExtra

if [[ "${bb_full_target}" == x86_64-apple-darwin* ]]; then
    # LLVM requires macOS SDK 10.14.
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/." 
    popd
fi

mkdir -p .local/bin
export PATH="`pwd`/.local/bin:$PATH"
curl -fLO https://github.com/bazelbuild/bazelisk/releases/download/v1.19.0/bazelisk-linux-amd64
mv bazel* .local/bin/bazel
chmod +x .local/bin/bazel

apk add py3-numpy py3-numpy-dev

ln -s `which ar` /usr/bin/ar

# wget https://github.com/JuliaLang/julia/releases/download/v1.10.3/julia-1.10.3.tar.gz
# tar -zxf  julia-1.10.3.tar.gz
# cd julia-1.10.3
# CC=$HOSTCC CXX=$HOSTCXX make -j
# export JULIA=`pwd`/julia
# $JULIA -c "add CUDA"
# cd ..

#mkdir -p .julia
#cd .julia

#export JULIA_PATH=/usr/local/julia
#export PATH=$JULIA_PATH/bin:$PATH

#	wget -O julia.tar.gz "https://julialang-s3.julialang.org/bin/musl/x64/1.8/julia-1.8.5-musl-x86_64.tar.gz"
	
#	mkdir -p "$JULIA_PATH"; 
#	tar -xzf julia.tar.gz -C "$JULIA_PATH" --strip-components 1; 
#	rm julia.tar.gz; 

# cd ..

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
BAZEL_FLAGS+=(--output_user_root=/workspace/bazel_root)

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
     
	if [[ "${bb_full_target}" == *86* ]]; then
        BAZEL_BUILD_FLAGS+=(--platforms=@//:darwin_x86_64)
        BAZEL_BUILD_FLAGS+=(--linkopt=-fuse-ld=lld)
    else
        BAZEL_BUILD_FLAGS+=(--platforms=@//:darwin_aarch64)
        sed -i '/gcc-install-dir/d'  "/opt/bin/x86_64-linux-musl-cxx11/x86_64-linux-musl-clang"
        sed -i '/gcc-install-dir/d'  "/opt/bin/x86_64-linux-musl-cxx11/x86_64-linux-musl-clang++"
        BAZEL_BUILD_FLAGS+=(--copt=-D__ARM_FEATURE_AES=1)
        BAZEL_BUILD_FLAGS+=(--copt=-D__ARM_NEON=1)
        BAZEL_BUILD_FLAGS+=(--copt=-D__ARM_FEATURE_SHA2=1)
        BAZEL_BUILD_FLAGS+=(--linkopt=-fuse-ld=lld)
    fi
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
    #export CUDA_HOME=${WORKSPACE}/destdir;
    #export PATH=$PATH:$CUDA_HOME/bin
    #export CUDACXX=$CUDA_HOME/bin/nvcc
    sed -i "s/getopts \\"/getopts \\"p/g" /sbin/ldconfig
    mkdir -p .local/bin
    echo "#!/bin/sh" > .local/bin/ldconfig
    echo "" >> .local/bin/ldconfig
    chmod +x .local/bin/ldconfig
    export PATH="`pwd`/.local/bin:$PATH"

    BAZEL_BUILD_FLAGS+=(--repo_env TF_NEED_CUDA=1)
    BAZEL_BUILD_FLAGS+=(--repo_env TF_NCCL_USE_STUB=1)
    BAZEL_BUILD_FLAGS+=(--repo_env HERMETIC_CUDA_COMPUTE_CAPABILITIES="sm_50,sm_60,sm_70,sm_80,compute_90")
    BAZEL_BUILD_FLAGS+=(--@local_config_cuda//:enable_cuda)
    BAZEL_BUILD_FLAGS+=(--@xla//xla/python:jax_cuda_pip_rpaths=true)
    BAZEL_BUILD_FLAGS+=(--repo_env=HERMETIC_CUDA_VERSION="12.3.2")
    BAZEL_BUILD_FLAGS+=(--repo_env=HERMETIC_CUDNN_VERSION="9.1.1")
    BAZEL_BUILD_FLAGS+=(--@local_config_cuda//cuda:include_hermetic_cuda_libs=true)

    #BAZEL_BUILD_FLAGS+=(--repo_env TF_NEED_ROCM=1)
    #BAZEL_BUILD_FLAGS+=(--define=using_rocm=true --define=using_rocm_hipcc=true)
    #BAZEL_BUILD_FLAGS+=(--action_env TF_ROCM_AMDGPU_TARGETS="gfx900,gfx906,gfx908,gfx90a,gfx1030")
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

# $JULIA --project=. -e "using Pkg; Pkg.instantiate(); Pkg.add(url=\"https://github.com/JuliaInterop/Clang.jl\")"
BAZEL_BUILD_FLAGS+=(--action_env=JULIA=$JULIA)
bazel ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :Builtin.inc.jl :Arith.inc.jl :Affine.inc.jl :Func.inc.jl :Enzyme.inc.jl :StableHLO.inc.jl :CHLO.inc.jl :VHLO.inc.jl
sed -i "s/^cc_library(/cc_library(linkstatic=True,/g" /workspace/bazel_root/*/external/llvm-project/mlir/BUILD.bazel
if [[ "${bb_full_target}" == *darwin* ]]; then
	bazel ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so || echo stage1
	sed -i.bak1 "/whole-archive/d" bazel-out/k8-$MODE/bin/libReactantExtra.so-2.params
#	sed -i.bak0 "/lld/d" bazel-out/k8-$MODE/bin/libReactantExtra.so-2.params
#	echo "-fuse-ld=lld" >> bazel-out/k8-$MODE/bin/libReactantExtra.so-2.params
	cat bazel-out/k8-$MODE/bin/libReactantExtra.so-2.params
	ls -all .
	ls -all bazel-out
	ls -all bazel-out/k8-$MODE/
	$CC @bazel-out/k8-$MODE/bin/libReactantExtra.so-2.params
else
	bazel ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} :libReactantExtra.so
fi
rm -f bazel-bin/libReactantExtraLib*
rm -f bazel-bin/libReactant*params
mkdir -p ${libdir}
cp -v bazel-bin/libReactantExtra.so ${libdir}
if [[ "${bb_full_target}" == *darwin* ]]; then
    mv ${libdir}/libReactantExtra.so ${libdir}/libReactantExtra.dylib
fi
if [[ "${bb_full_target}" == *mingw* ]]; then
    mv ${libdir}/libReactantExtra.so ${libdir}/libReactantExtra.dll
fi
cp -v bazel-bin/*.jl ${prefix}
"""

# determine exactly which tarballs we should build
builds = []
    
# Dependencies that must be installed before this package can be built

dependencies = Dependency[]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libReactantExtra", "libReactantExtra"],
                   :libReactantExtra), #; dlopen_flags=[:RTLD_NOW,:RTLD_DEEPBIND]),
    FileProduct("Affine.inc.jl", :Affine_inc_jl),
    FileProduct("Arith.inc.jl", :Arith_inc_jl),
    FileProduct("Builtin.inc.jl", :Builtin_inc_jl),
    FileProduct("Enzyme.inc.jl", :Enzyme_inc_jl),
    FileProduct("Func.inc.jl", :Func_inc_jl),
    FileProduct("StableHLO.inc.jl", :StableHLO_inc_jl),
    FileProduct("CHLO.inc.jl", :CHLO_inc_jl),
    FileProduct("VHLO.inc.jl", :VHLO_inc_jl),
    # FileProduct("libMLIR_h.jl", :libMLIR_h_jl),
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
platforms = filter(p -> !(arch(p) == "aarch64" && Sys.islinux(p)), platforms)
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
# platforms = filter(p -> cxxstring_abi(p) == "cxx11", platforms)

augment_platform_block="""
    using Base.BinaryPlatforms

    const Reactant_UUID = Base.UUID("0192cb87-2b54-54ad-80e0-3be72ad8a3c0")
    const preferences = Base.get_preferences(Reactant_UUID)
    Base.record_compiletime_preference(Reactant_UUID, "mode")
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
    
    #module __CUDA
    #    $(CUDA.augment::String)
    #end

    function augment_platform!(platform::Platform)
        #__CUDA.augment_platform!(platform)

        mode = get(ENV, "REACTANT_MODE", something(mode_preference, "opt"))
        if !haskey(platform, "mode")
            platform["mode"] = mode
        end

        return platform
    end
    """

for mode in ("opt", "dbg"), platform in platforms
    augmented_platform = deepcopy(platform)
    augmented_platform["mode"] = mode
    cuda_deps = []

    # Skip debug builds on linux
    if mode == "dbg" && !Sys.isapple(platform)
        continue
    end

    prefix="export MODE="*mode*"\n\n"
    platform_sources = BinaryBuilder.AbstractSource[sources...]
    if Sys.isapple(platform)
        push!(platform_sources,
              ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                            "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"))
    end

    # if CUDA.is_supported(platform)
    #     cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)
    #     push!(cuda_deps, BuildDependency(PackageSpec(name="CUDNN_jll")))
    #     push!(cuda_deps, BuildDependency(PackageSpec(name="TensorRT_jll")))
    #     push!(cuda_deps, BuildDependency(PackageSpec(name="CUDA_full_jll")))
    #     prefix *= "export CUDA_VERSION=\"\"\n"
    # end

    should_build_platform(triplet(augmented_platform)) || continue
    push!(builds, (;
                   dependencies=[dependencies; cuda_deps], products, sources=platform_sources,
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
                   preferred_gcc_version=v"10", julia_compat="1.6",
                   augment_platform_block, lazy_artifacts=true)
end

