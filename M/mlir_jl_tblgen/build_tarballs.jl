using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

name = "mlir_jl_tblgen"
repo = "https://github.com/JuliaLabs/MLIR.jl.git"
version = v"0.0.10"

llvm_versions = [v"14.0.6", v"15.0.7", v"16.0.6", v"17.0.6", v"18.1.7", v"19.1.1"]

sources = [
    GitSource(repo, "1e5e8a2b7b43ec79ec2132cf7a90a5f96d97b4da"),
]

# Bash recipe for building across all platforms
script = raw"""
cd MLIR.jl/deps/tblgen

if [[ "${bb_full_target}" == x86_64-apple-darwin* ]]; then
    # LLVM 15+ requires macOS SDK 10.14.
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.14
    popd
fi

CMAKE_FLAGS=()
# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=RelWithDebInfo)
# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
# Tell CMake where LLVM and MLIR are
CMAKE_FLAGS+=(-DLLVM_DIR="${prefix}/lib/cmake/llvm")
CMAKE_FLAGS+=(-DMLIR_DIR="${prefix}/lib/cmake/mlir")
# Force linking against shared lib
CMAKE_FLAGS+=(-DLLVM_LINK_LLVM_DYLIB=ON)
# Build the library
CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)
cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}

ninja -C build -j ${nproc} install
"""

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
        BuildDependency(PackageSpec(name=llvm_name, version=llvm_version))
    ]

    # The products that we will ensure are always built
    products = Product[
        ExecutableProduct("mlir-jl-tblgen", :mlir_jl_tblgen),
    ]

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

    if llvm_version >= v"15"
        # We don't build LLVM 15 for i686-linux-musl.
        filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
    end

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, llvm_assertions)

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

