using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "Reactant"
repo = "https://github.com/EnzymeAD/Reactant.jl.git"
version = v"0.0.1"

sources = [
   GitSource(repo,"23de1939a0f5a798079cd80a336654b11ad53047"),
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

apk add bazel --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
apk add py3-numpy py3-numpy-dev

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

export BAZEL_CXXOPTS="-std=c++17"
BAZEL_FLAGS=()
BAZEL_BUILD_FLAGS=()

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
    
BAZEL_BUILD_FLAGS+=(--host_cpu=k8)
BAZEL_BUILD_FLAGS+=(--host_crosstool_top=@//:ygg_cross_compile_toolchain_suite)
# BAZEL_BUILD_FLAGS+=(--extra_execution_platforms=@xla//tools/toolchains/cross_compile/config:linux_x86_64)

if [[ "${bb_full_target}" == *darwin* ]]; then
    BAZEL_BUILD_FLAGS+=(--define=build_with_mkl=false --define=enable_mkl=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_x86_32_1=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_x86_64_1=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_x86_64_2=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_aarch64=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_ppc64=false)
    BAZEL_BUILD_FLAGS+=(--define=gcc_linux_s390x=false)
    BAZEL_BUILD_FLAGS+=(--apple_platform_type=macos)
    BAZEL_BUILD_FLAGS+=(--define=no_nccl_support=true)
    if [[ "${bb_full_target}" == *86* ]]; then
        BAZEL_BUILD_FLAGS+=(--platforms=@xla//tools/toolchains/cross_compile/config:darwin_x86_64)
        BAZEL_BUILD_FLAGS+=(--cpu=darwin)
    fi
    BAZEL_BUILD_FLAGS+=(--crosstool_top=@xla//tools/toolchains/cross_compile/cc:cross_compile_toolchain_suite)
    BAZEL_BUILD_FLAGS+=(--define=clang_macos_x86_64=true)
    BAZEL_BUILD_FLAGS+=(--define HAVE_LINK_H=0)
    BAZEL_BUILD_FLAGS+=(--macos_minimum_os=10.14)
    export MACOSX_DEPLOYMENT_TARGET=10.14
    BAZEL_BUILD_FLAGS+=(--action_env=MACOSX_DEPLOYMENT_TARGET=10.14)
    BAZEL_BUILD_FLAGS+=(--host_action_env=MACOSX_DEPLOYMENT_TARGET=10.14)
    BAZEL_BUILD_FLAGS+=(--repo_env=MACOSX_DEPLOYMENT_TARGET=10.14)
    BAZEL_BUILD_FLAGS+=(--test_env=MACOSX_DEPLOYMENT_TARGET=10.14)
    BAZEL_BUILD_FLAGS+=(--incompatible_remove_legacy_whole_archive)
    BAZEL_BUILD_FLAGS+=(-s)
    env
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

# julia --project=. -e "using Pkg; Pkg.instantiate(); Pkg.add(url=\"https://github.com/JuliaInterop/Clang.jl\", rev=\"vc/cxx_parse2\")"
BAZEL_BUILD_FLAGS+=(--action_env=JULIA=julia)
bazel ${BAZEL_FLAGS[@]} build -s ${BAZEL_BUILD_FLAGS[@]} //...
rm -f bazel-bin/libReactantExtraLib*
rm -f bazel-bin/libReactant*params
mkdir -p ${libdir}
cp -v bazel-bin/libReactantExtra* ${libdir}
cp -v bazel-bin/*.jl ${prefix}
"""

augment_platform_block = ""

# determine exactly which tarballs we should build
builds = []
    
# Dependencies that must be installed before this package can be built

dependencies = Dependency[]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libReactantExtra", "libReactantExtra"],
                   :libReactantExtra),
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

# go sdk has weird issue for arm linux, removing for now
platforms = filter(p -> !(arch(p) == "aarch64" && Sys.islinux(p)), platforms)
platforms = filter(p -> !(arch(p) == "armv6l" && Sys.islinux(p)), platforms)
platforms = filter(p -> !(arch(p) == "armv7l" && Sys.islinux(p)), platforms)

# XLA has weird issue on musl
# [22:07:03] bazel-out/k8-opt/bin/external/xla/xla/autotuning.pb.h:249:11: error: expected unqualified-id before ‘unsigned’
# [22:07:03]   249 |   int32_t major() const;
platforms = filter(p -> !(libc(p) == "musl"), platforms)

# Windows has a cuda configure issue, to investigate either fixing/disabling cuda
platforms = filter(p -> !(Sys.iswindows(p)), platforms)

# NSync is picking up wrong stuff for cross compile, to deal with later
# 02] ./external/nsync//platform/c++11.futex/platform.h:24:10: fatal error: 'linux/futex.h' file not found
# [00:20:02] #include <linux/futex.h>
platforms = filter(p -> !(Sys.isfreebsd(p)), platforms)
 platforms = filter(p -> (Sys.isapple(p)), platforms)
# platforms = filter(p -> !(Sys.isapple(p)), platforms)


for platform in platforms
    augmented_platform = deepcopy(platform)

    platform_sources = BinaryBuilder.AbstractSource[sources...]
    if Sys.isapple(platform)
        push!(platform_sources,
              ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                            "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"))
    end

    should_build_platform(triplet(augmented_platform)) || continue
    push!(builds, (;
        dependencies, products, sources=platform_sources,
        platforms=[augmented_platform],
    ))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, build.products, build.dependencies;
                   preferred_gcc_version=v"10", julia_compat="1.6",
                   augment_platform_block, lazy_artifacts=true)
end

