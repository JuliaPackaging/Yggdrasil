# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SPIRV_Tools"
version = v"2024.4"

# Collection of sources required to build SPIRV-Tools
sources = [
    GitSource("https://github.com/KhronosGroup/SPIRV-Tools.git", "4d2f0b40bfe290dea6c6904dafdf7fd8328ba346"),
    # vendored dependencies, see the DEPS file
    GitSource("https://github.com/google/effcee.git", "2c97e5689ed8d7ab6ae5820f884f03a601ae124b"),
    GitSource("https://github.com/google/googletest", "35d0c365609296fa4730d62057c487e3cfa030ff"),
    GitSource("https://github.com/google/re2.git", "6dcd83d60f7944926bfd308cc13979fc53dd69ca"),
    GitSource("https://github.com/KhronosGroup/SPIRV-Headers.git", "3f17b2af6784bfa2c5aa5dbb8e0e74a607dd8b3b"),
    # updated macOS SDK
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

# Bash recipe for building across all platforms
script = raw"""
# put vendored dependencies in places they will be picked up by the build system
mv effcee SPIRV-Tools/external/effcee
mv re2 SPIRV-Tools/external/re2
mv googletest SPIRV-Tools/external/googletest
mv SPIRV-Headers SPIRV-Tools/external/spirv-headers

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Install a newer SDK which supports `std::filesystem`
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
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("spirv-as", :spirv_as),
    ExecutableProduct("spirv-dis", :spirv_dis),
    ExecutableProduct("spirv-val", :spirv_val),
    ExecutableProduct("spirv-opt", :spirv_opt),
    ExecutableProduct("spirv-cfg", :spirv_cfg),
    ExecutableProduct("spirv-link", :spirv_link),
    ExecutableProduct("spirv-lint", :spirv_lint),
    ExecutableProduct("spirv-reduce", :spirv_reduce),
    LibraryProduct("libSPIRV-Tools-shared", :libSPIRV_Tools),
]

# Dependencies that must be installed before this package can be built
dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10") # requires C++17 + filesystem
