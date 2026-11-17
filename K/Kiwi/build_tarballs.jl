# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# For should_build_platform
include("../../fancy_toys.jl")

name = "Kiwi"
version = v"0.24.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/bab2min/Kiwi.git",
              "724d00718f527bac3f8aef2f6ae3b6523b2aae74"), # v0.24.1
    # Header-only B-tree fork vendored by Kiwi as a git submodule; no JLL exists.
    GitSource("https://github.com/bab2min/cpp-btree.git",
              "226ce3aed24702bef1b03dba4b3cb55bc0bf31dd"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Kiwi

# Build against the JLL dependencies instead of the git submodules in third_party/
atomic_patch -p1 ../patches/kiwi-system-deps.patch
# MinGW headers are lowercase; this only matters on case-sensitive cross-compilation hosts
sed -i 's/#include <Windows.h>/#include <windows.h>/' include/kiwi/Mmap.h
rm -rf third_party/cpp-btree
cp -r ../cpp-btree third_party/cpp-btree

if [[ "${target}" == *-mingw32 ]]; then
    # Equivalent of MSVC /bigobj, which upstream uses: the templated SIMD kernels exceed the
    # default COFF section count. Their long section names also need binutils >= 2.41, which
    # encodes string table offsets above 9999999 in base64 ("string table overflow" otherwise).
    export CXXFLAGS="-Wa,-mbig-obj"
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_VERBOSE_MAKEFILE=OFF \
    -DKIWI_USE_SYSTEM_DEPS=ON \
    -DKIWI_BUILD_STATIC=OFF \
    -DKIWI_BUILD_CLI=OFF \
    -DKIWI_BUILD_EVALUATOR=OFF \
    -DKIWI_BUILD_MODEL_BUILDER=OFF \
    -DKIWI_BUILD_TEST=OFF
cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE NOTICE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
# Restricted to the platforms CPUInfo_jll is built for.
platforms = supported_platforms()
filter!(p -> arch(p) != "powerpc64le", platforms)
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)
# libkiwi uses std::string internally (C API only exposes C types, but the auditor requires both ABIs)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libkiwi", :libkiwi),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Kiwi pins Eigen 3.4.0; header-only, so only needed at build time
    BuildDependency(PackageSpec(name="Eigen_jll", version=v"3.4.0+0")),
    BuildDependency(PackageSpec(name="nlohmann_json_jll", version=v"3.12.0+0")),
    Dependency("StreamVByte_jll"; compat="2.0.0"),
    Dependency("CPUInfo_jll"; compat="0.0.20260415"),
    Dependency("mimalloc_jll"; compat="3.5.3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 11: C++17 and AVX-VNNI intrinsics (Kiwi enables these with GCC >= 11).
# Windows needs GCC 13 for its binutils 2.41 (see the comment in the script above); the other
# platforms stay on GCC 11 to keep the libstdc++ requirement low.
builds = [
    (filter(!Sys.iswindows, platforms), v"11"),
    (filter(Sys.iswindows, platforms), v"13"),
]
for (platforms, gcc_version) in builds
    any(should_build_platform.(triplet.(platforms))) || continue
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                   julia_compat="1.6", preferred_gcc_version=gcc_version)
end
