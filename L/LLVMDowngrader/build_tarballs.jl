using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

name = "LLVMDowngrader"
repo = "https://github.com/JuliaGPU/llvm-downgrade"
version = v"0.3"

llvm_versions = [v"13.0.1", v"14.0.6", v"15.0.7", v"16.0.6", v"17.0.6"]

# Collection of sources required to build LLVMDowngrader
sources = Dict(
    v"13.0.1" => [GitSource(repo, "5538d5106dd4779c9aa475a78cfbe9f70053f44c")],
    v"14.0.6" => [GitSource(repo, "07810b82a167176a9e81f59435a6ac551dfd52e9")],
    v"15.0.7" => [GitSource(repo, "cbfa9715397a7707b6c1ff94ab325af1fab99220")],
    v"16.0.6" => [GitSource(repo, "c74dc63cd74b1e92919d8f9df1ce7897a9db4e7f")],
    v"17.0.6" => [GitSource(repo, "c09ff8ef76ddc5adb4169a12e3e5ceb1b1a23df5")],
)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# Bash recipe for building across all platforms
script = raw"""
cd llvm-downgrade/llvm
LLVM_SRCDIR=$(pwd)

install_license LICENSE.TXT

# The very first thing we need to do is to build llvm-tblgen for x86_64-linux-muslc
# This is because LLVM's cross-compile setup is kind of borked, so we just
# build the tools natively ourselves, directly.  :/

# Build llvm-tblgen and llvm-config
mkdir ${WORKSPACE}/bootstrap
pushd ${WORKSPACE}/bootstrap
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=host)
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${MACHTYPE})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm')
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=False)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})
cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} llvm-tblgen llvm-config
popd

# Let's do the actual build within the `build` subdirectory
mkdir ${WORKSPACE}/build && cd ${WORKSPACE}/build
CMAKE_FLAGS=()

# Tell LLVM where our pre-built tblgen tools are
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/bootstrap/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/bootstrap/bin/llvm-config)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Turn on ZLIB
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=ON)
# Turn off XML2
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

# Disable useless things like docs, terminfo, etc....
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=Off)
CMAKE_FLAGS+=(-DLLVM_ENABLE_TERMINFO=Off)
CMAKE_FLAGS+=(-DHAVE_HISTEDIT_H=Off)
CMAKE_FLAGS+=(-DHAVE_LIBEDIT=Off)

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} tools/llvm-as/install
"""

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("llvm-as", :llvm_as),
]

augment_platform_block = """
    using Base.BinaryPlatforms

    $(LLVM.augment)

    function augment_platform!(platform::Platform)
        augment_llvm!(platform)
    end"""

# determine exactly which tarballs we should build
builds = []
for llvm_version in llvm_versions, llvm_assertions in (false, true)
    # Dependencies that must be installed before this package can be built
    llvm_name = llvm_assertions ? "LLVM_full_assert_jll" : "LLVM_full_jll"
    dependencies = [
        BuildDependency(PackageSpec(name=llvm_name, version=llvm_version)),
        Dependency("Zlib_jll")
    ]

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, llvm_assertions)

        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (;
            dependencies,
            sources=sources[llvm_version],
            platforms=[augmented_platform],
            preferred_gcc_version=(llvm_version >= v"16" ? v"10" : v"7")
        ))
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, products, build.dependencies;
                   build.preferred_gcc_version, julia_compat="1.6",
                   augment_platform_block, lazy_artifacts=true)
end
