using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "ReactantExtra"
repo = "https://github.com/EnzymeAD/Reactant.jl.git"
version = v"0.0.1"

sources = [
   GitSource(repo, "058a026d66e9717cea0fbcacd347cc2fc2c559a9"),
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
    export MACOSX_DEPLOYMENT_TARGET=10.14
    popd
fi

if command -v apk &> /dev/null
then
    apk add bazel --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
    apk add py3-numpy py3-numpy-dev
elif command -v brew &> /dev/null
then
    brew install bazel
elif command -v choco &> /dev/null
then
    choco install bazel
else
    mkdir -p .local/bin

    mkdir baz && cd baz
    wget https://github.com/bazelbuild/bazel/releases/download/6.1.2/bazel-6.1.2-dist.zip
    unzip -q *.zip
    rm *.zip
    env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
    ls
    cd ..

    mv baz/output/bazel .local/bin/bazel
fi

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

# julia --project=. -e "using Pkg; Pkg.instantiate(); Pkg.add(url=\"https://github.com/JuliaInterop/Clang.jl\", rev=\"vc/cxx_parse2\")"
BAZEL_BUILD_FLAGS+=(--action_env=JULIA=julia)
bazel ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} ...
cp bazel-bin/libReactantExtra* ${prefix}
cp bazel-bin/*.jl ${prefix}
"""

augment_platform_block = ""

# determine exactly which tarballs we should build
builds = []
    
# Dependencies that must be installed before this package can be built

dependencies = []

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libReactantExtra", "libReactantExtra"],
                   :libReactantExtra, dont_dlopen=true),
    FileProduct("Affine.inc.jl", Symbol("Affine.inc.jl")),
    FileProduct("Arith.inc.jl", Symbol("Arith.inc.jl")),
    FileProduct("Builtin.inc.jl", Symbol("Builtin.inc.jl")),
    FileProduct("Enzyme.inc.jl", Symbol("Enzyme.inc.jl")),
    FileProduct("Func.inc.jl", Symbol("Func.inc.jl")),
    FileProduct("StableHLO.inc.jl", Symbol("StableHLO.inc.jl")),
    FileProduct("CHLO.inc.jl", Symbol("CHLO.inc.jl")),
    FileProduct("VHLO.inc.jl", Symbol("VHLO.inc.jl")),
    # FileProduct("libMLIR_h.jl", Symbol("libMLIR_h.jl")),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

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

