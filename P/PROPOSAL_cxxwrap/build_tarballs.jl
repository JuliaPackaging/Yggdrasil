# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Include libjulia common definitions for Julia version handling
include("../../L/libjulia/common.jl")

name = "PROPOSAL_cxxwrap"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jlazar17/PROPOSAL_cxxwrap.git",
              "f0cbc2bcd40ea9e326661ac42137f138bff5a3dc"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p build && cd build

cmake ../PROPOSAL_cxxwrap \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DJlCxx_DIR=${prefix}/lib/cmake/JlCxx \
    -DJulia_PREFIX=${prefix} \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_CXX_STANDARD_REQUIRED=ON

make -j${nproc}
make install

install_license $WORKSPACE/srcdir/PROPOSAL_cxxwrap/LICENSE.md
"""

# Filter Julia versions: remove versions below current LTS (1.10)
filter!(x -> x >= v"1.10", julia_versions)

# Use libjulia platforms for CxxWrap compatibility
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# Filter to platforms supported by both PROPOSAL_jll and libcxxwrap_julia
filter!(p -> libc(p) != "musl", platforms)
filter!(p -> !Sys.iswindows(p), platforms)
filter!(p -> !Sys.isfreebsd(p), platforms)
filter!(p -> arch(p) != "riscv64", platforms)
filter!(p -> arch(p) != "armv6l", platforms)
filter!(p -> arch(p) != "armv7l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libPROPOSAL_cxxwrap", :libPROPOSAL_cxxwrap),
]

# Dependencies
# Note: Eigen_jll and nlohmann_json_jll are BuildDependencies for PROPOSAL_jll,
# but PROPOSAL's cmake config requires them, so we need them here too.
dependencies = [
    BuildDependency("libjulia_jll"),
    BuildDependency("Eigen_jll"),
    BuildDependency("nlohmann_json_jll"),
    Dependency("PROPOSAL_jll"; compat="~7.6.2"),
    Dependency("libcxxwrap_julia_jll"; compat="0.14.7"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.6")
