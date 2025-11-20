# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "TVM"
version = v"0.22.0"
llvm_versions = [v"15.0.7", v"16.0.6", v"18.1.7", v"20.1.8"]

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/apache/tvm.git",
        "9dbf3f22ff6f44962472f9af310fda368ca85ef2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tvm
install_license LICENSE 
git submodule update --init --recursive
# setup LLVM_LIBS manually for non-Linux OS
if [[ "$target" == *darwin* ]]; then
    export LLVM_LIBS="${libdir}/libLLVM-#LLVM_MAJOR#.#LLVM_MINOR#.dylib"
elif [[ "$target" == *mingw* ]]; then
    export LLVM_LIBS="${bindir}/libLLVM-#LLVM_MAJOR#jl.dll"
else
    export LLVM_LIBS="${libdir}/libLLVM-#LLVM_MAJOR#jl.so"
fi
cmake -B ../../build -DCMAKE_INSTALL_PREFIX=${prefix} \
         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
         -DUSE_ALTERNATIVE_LINKER=OFF \
         -DCMAKE_BUILD_TYPE=Release \
         -DUSE_LLVM=ON \
         -DLLVM_LIBS=${LLVM_LIBS} \
         -G Ninja
ninja -C ../../build
ninja -C ../../build install
"""

# LLVM 15+ requires macOS SDK 10.14.
sources, script = require_macos_sdk("10.14", sources, script)

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
        Dependency(PackageSpec(name="Zlib_jll")),
        Dependency(PackageSpec(name="XML2_jll")),
        Dependency(PackageSpec(name="libLLVM_jll")),
        Dependency(PackageSpec(name="TVMFFI_jll")),
        BuildDependency(PackageSpec(name=llvm_name, version=llvm_version)),
        BuildDependency(PackageSpec(name="MLIR_jll", version=llvm_version)),
    ]

    # The products that we will ensure are always built
    products = [
        LibraryProduct("libtvm", :libtvm),
        LibraryProduct("libtvm_runtime", :libtvm_runtime),
    ]

    platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))
    ## Filter out musl, FreeBSD and Windows
    filter!(p -> !(libc(p) == "musl" || Sys.isfreebsd(p) || Sys.iswindows(p)), platforms)
    ## We only have LLVM builds for RISC-V starting from LLVM 19
    if llvm_version < v"19"
        filter!(p -> !(arch(p) == "riscv64"), platforms)
    end
    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, llvm_assertions)

        platform_sources = BinaryBuilder.AbstractSource[sources...]
        
        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (;
            dependencies, products,
            sources=platform_sources,
            platforms=[augmented_platform],
            script=replace(script, "#LLVM_MAJOR#" => string(llvm_version.major), 
                                   "#LLVM_MINOR#" => string(llvm_version.minor))
        ))
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
        name, version, build.sources, build.script,
        build.platforms, build.products, build.dependencies;
        preferred_gcc_version=v"8", julia_compat="1.6",
        augment_platform_block, lazy_artifacts=true)
end
