# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

name = "TVM"
version = v"0.10.0"
llvm_versions = [v"12.0.1", v"13.0.1", v"14.0.5"]

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://dlcdn.apache.org/tvm/tvm-v$(version)/apache-tvm-src-v$(version).tar.gz", "2da001bf847636b32fc7a34f864abf01a46c69aaef0ff37cfbfbcc2eb5b0fce4"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
        "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/apache-tvm-src*/
install_license LICENSE 
mkdir build && cd build
# setup LLVM_LIBS manually for non-Linux OS
if [[ "$target" == *darwin* ]]; then
    # Work around "'value' is unavailable"
    export MACOSX_DEPLOYMENT_TARGET=10.15
    # ...and install a newer SDK which supports `std::filesystem`
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
    export LLVM_LIBS="${libdir}/libLLVM-#LLVM_VER#.0.dylib"
else
    if [[ "$target" == *mingw* ]]; then
        export LLVM_LIBS="${bindir}/libLLVM-#LLVM_VER#jl.dll"
    else
        export LLVM_LIBS="${libdir}/libLLVM-#LLVM_VER#jl.so"
    fi
fi
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
         -DUSE_ALTERNATIVE_LINKER=OFF \
         -DCMAKE_BUILD_TYPE=Release \
         -DUSE_LLVM=ON \
         -DLLVM_LIBS=${LLVM_LIBS} \
         -G Ninja
ninja
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),

    # dll import woes
    # Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms)

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
        BuildDependency(PackageSpec(name=llvm_name, version=llvm_version)),
        BuildDependency(PackageSpec(name="MLIR_jll", version=llvm_version)),
    ]

    # The products that we will ensure are always built
    products = [
        LibraryProduct("libtvm", :libtvm),
        LibraryProduct("libtvm_runtime", :libtvm_runtime),
    ]

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, llvm_assertions)

        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (;
            dependencies, products,
            platforms=[augmented_platform],
            script=replace(script, "#LLVM_VER#" => string(llvm_version.major))
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
        name, version, sources, build.script,
        build.platforms, build.products, build.dependencies;
        preferred_gcc_version=v"8", julia_compat="1.6",
        augment_platform_block, lazy_artifacts=true)
end
