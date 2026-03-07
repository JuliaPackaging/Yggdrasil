using BinaryBuilder, Pkg

name = "Quiver"
version = v"0.5.0"

include("../../platforms/macos_sdks.jl")

sources = [
    GitSource("https://github.com/psrenergy/quiver.git",
              "d99e2f4cb7a82e7bc8a1a29c5a061af378829762"),
]

script = raw"""
# Use CMake_jll instead of the base image CMake
apk del cmake

cd ${WORKSPACE}/srcdir/quiver

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DQUIVER_BUILD_TESTS=OFF \
    -DQUIVER_BUILD_C_API=ON \
    -DHAVE_GNU_STRERROR_R_EXITCODE=0 \
    -DHAVE_GNU_STRERROR_R_EXITCODE__TRYRUN_OUTPUT=""

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE
"""

sources, script = require_macos_sdk("10.15", sources, script)

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libquiver", :libquiver),
    LibraryProduct("libquiver_c", :libquiver_c),
]

dependencies = [
    # Quiver deps require CMake >= 3.26
    HostBuildDependency(PackageSpec(; name = "CMake_jll", version = "3.26.0")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.7",
               preferred_gcc_version=v"13")
