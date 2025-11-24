# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "SPIRV_Tools"
version = v"2025.4"

# Collection of sources required to build SPIRV-Tools
sources = [
    GitSource("https://github.com/KhronosGroup/SPIRV-Tools.git", "7f2d9ee926f98fc77a3ed1e1e0f113b8c9c49458"),
    # vendored dependencies, see the DEPS file
    GitSource("https://github.com/google/effcee.git", "514b52ec61609744d7e587d93a7ef9b60407ab45"),
    GitSource("https://github.com/google/googletest", "50b8600c63c5487e901e2845a0f64d384a65f75d"),
    GitSource("https://github.com/google/re2.git", "6569a9a3df256f4c0c3813cb8ee2f8eef6e2c1fb"),
    GitSource("https://github.com/KhronosGroup/SPIRV-Headers.git", "01e0577914a75a2569c846778c2f93aa8e6feddd"),
]

# Bash recipe for building across all platforms
script = raw"""
# use CMake from JLLs
apk del cmake

# put vendored dependencies in places they will be picked up by the build system
mv effcee SPIRV-Tools/external/effcee
mv re2 SPIRV-Tools/external/re2
mv googletest SPIRV-Tools/external/googletest
mv SPIRV-Headers SPIRV-Tools/external/spirv-headers

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.15
    popd
fi

cd SPIRV-Tools
install_license LICENSE

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Build all shared libraries (downstream projects seem to depend on it)
CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)
CMAKE_FLAGS+=(-DSPIRV_TOOLS_BUILD_STATIC=OFF)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Skip tests
CMAKE_FLAGS+=(-DSPIRV_SKIP_TESTS=ON)

# Don't use -Werror
CMAKE_FLAGS+=(-DSPIRV_WERROR=OFF)

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install

# Remove unwanted static libraries
rm -f $prefix/lib/*.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("spirv-as", :spirv_as),
    ExecutableProduct("spirv-dis", :spirv_dis),
    ExecutableProduct("spirv-val", :spirv_val),
    ExecutableProduct("spirv-opt", :spirv_opt),
    ExecutableProduct("spirv-cfg", :spirv_cfg),
    ExecutableProduct("spirv-link", :spirv_link),
    ExecutableProduct("spirv-lint", :spirv_lint),
    ExecutableProduct("spirv-objdump", :spirv_objdump),
    ExecutableProduct("spirv-reduce", :spirv_reduce),
    LibraryProduct("libSPIRV-Tools", :libSPIRV_Tools),
    LibraryProduct("libSPIRV-Tools-opt", :libSPIRV_Tools_opt),
    LibraryProduct("libSPIRV-Tools-diff", :libSPIRV_Tools_diff),
    LibraryProduct("libSPIRV-Tools-link", :libSPIRV_Tools_link),
    LibraryProduct("libSPIRV-Tools-lint", :libSPIRV_Tools_lint),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # CMake 3.22.1 or higher is required
    HostBuildDependency("CMake_jll")
]

builds = []
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    # On macOS, we need to use a newer SDK which supports `std::filesystem`
    platform_sources = if Sys.isapple(platform)
        [sources;
         ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                       "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62")]
    else
        sources
    end

    push!(builds, (; platform, sources=platform_sources))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   [build.platform], products, dependencies;
                   preferred_gcc_version=v"10", # requires C++17 + filesystem
                   julia_compat="1.6")
end
