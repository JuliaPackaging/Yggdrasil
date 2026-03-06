using BinaryBuilder, Pkg

name = "Quiver"
version = v"0.5.0"

include("../../platforms/macos_sdks.jl")

sources = [
    GitSource("https://github.com/psrenergy/quiver.git",
              "f0dff1df461b83303d97e51605167c45a50b20bd"),
]

script = raw"""
# Use CMake_jll instead of the base image CMake
apk del cmake

cd ${WORKSPACE}/srcdir/quiver

# Force apple to use gcc
toolchain="${CMAKE_TARGET_TOOLCHAIN}"
if [[ "${target}" == *-apple-* ]]; then
    toolchain="${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake"
    
    # Apparently, we also need to remove the -ld_classic link option
    sed -i '/add_link_options("-ld_classic")/d' src/CMakeLists.txt
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${toolchain} \
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
    HostBuildDependency(PackageSpec(; name = "CMake_jll")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.7",
               preferred_gcc_version=v"13")
