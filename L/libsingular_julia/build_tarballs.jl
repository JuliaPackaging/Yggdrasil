# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "libsingular_julia"
version = v"0.47.7"

# Collection of sources required to build libsingular-julia
sources = [
    GitSource("https://github.com/oscar-system/Singular.jl.git", "c3e4bb2e857918a4f023443ef5c7958ad46e42ee"),
]

# Bash recipe for building across all platforms
script = raw"""
cd Singular.jl/deps/src
cmake . -B build \
   -DJulia_PREFIX="$prefix" \
   -DSingular_PREFIX="$prefix" \
   -DCMAKE_INSTALL_PREFIX="$prefix" \
   -DCMAKE_FIND_ROOT_PATH="$prefix" \
   -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
   -DCMAKE_CXX_STANDARD=14 \
   -DCMAKE_BUILD_TYPE=Release

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}

# store tree hash of the source directory
git ls-tree HEAD .. | cut -c13-52 > ${libdir}/libsingular_julia.treehash

install_license ../../LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
filter!(>=(v"1.10"), julia_versions)
platforms = vcat(libjulia_platforms.(julia_versions)...)
filter!(!Sys.iswindows, platforms) # Singular does not support Windows

# Exclude aarch64 FreeBSD for the time being
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsingular_julia", :libsingular_julia),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(;name="libjulia_jll", version=v"1.10.19")),
    BuildDependency("GMP_jll"),
    BuildDependency("MPFR_jll"),
    Dependency("libcxxwrap_julia_jll"; compat = "~0.14.3"),
    # we do not set a compat entry for Singular_jll -- instead we leave it to
    # Singular.jl to ensure the right versions of libsingular_julia_jll and
    # Singular_jll are paired. This gives us flexibility in the development
    # setup there.
    Dependency("Singular_jll", v"404.101.400"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"8", julia_compat="1.10")

# rebuild trigger: 0
