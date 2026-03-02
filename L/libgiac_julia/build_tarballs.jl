# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "libgiac_julia"
version = v"0.3.0"

# Collection of sources required to build libgiac_julia
sources = [
    GitSource(
        "https://github.com/s-celles/libgiac-julia-wrapper.git",
        "29ad137257d9c902a1c5e5ac580558219003619f"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgiac-julia-wrapper

# Help CMake find GIAC
export GIAC_ROOT="${prefix}"

# Build with CMake
cmake -B build \
   -DJulia_PREFIX="${prefix}" \
   -DGIAC_INCLUDE_DIR="${includedir}/giac" \
   -DGIAC_LIBRARY="${libdir}/libgiac.${dlext}" \
   -DGMP_LIBRARY="${libdir}/libgmp.${dlext}" \
   -DCMAKE_INSTALL_PREFIX="${prefix}" \
   -DCMAKE_FIND_ROOT_PATH="${prefix}" \
   -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
   -DCMAKE_BUILD_TYPE=Release

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgiac_wrapper", :libgiac_wrapper),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(;name="libjulia_jll", version="1.11.0")),
    BuildDependency("GMP_jll"),
    BuildDependency("MPFR_jll"),
    Dependency("libcxxwrap_julia_jll"; compat = "~0.14"),
    Dependency("GIAC_jll"; compat = "~2.0.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"10", julia_compat=libjulia_julia_compat(julia_versions))
