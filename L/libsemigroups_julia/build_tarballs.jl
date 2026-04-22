# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "libsemigroups_julia"
version = v"0.0.1"

# Collection of sources required to build libsemigroups_julia
sources = [
    GitSource("https://github.com/libsemigroups/Semigroups.jl.git",
        "ea11f697ebae7417e24a8140c35e4318fd308bc2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd Semigroups.jl*/deps/src
cmake . -B build \
   -DJulia_PREFIX="$prefix" \
   -DCMAKE_INSTALL_PREFIX="$prefix" \
   -DCMAKE_FIND_ROOT_PATH="$prefix" \
   -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
   -DCMAKE_CXX_STANDARD=17 \
   -DCMAKE_BUILD_TYPE=Release \
   -DLIBSEMIGROUPS_INCLUDE_DIR="${prefix}/include" \
   -DLIBSEMIGROUPS_LIBRARY_DIR="${libdir}"

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}

# store tree hash of the source directory
git ls-tree HEAD .. | cut -c13-52 > ${libdir}/libsemigroups_julia.treehash

install_license ../../LICENSE
"""

sources, script = require_macos_sdk("10.14", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
filter!(>=(v"1.10"), julia_versions)
platforms = vcat(libjulia_platforms.(julia_versions)...)
filter!(!Sys.iswindows, platforms) # libsemigroups does not support Windows

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsemigroups_julia", :libsemigroups_julia),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="libjulia_jll", version="1.11.0")),
    Dependency("libcxxwrap_julia_jll"; compat="~0.14.5"),
    # we do not set a compat entry for libsemigroups_jll -- instead we leave it
    # to Semigroups.jl to ensure the right versions of libsemigroups_julia_jll
    # and libsemigroups_jll are paired.
    Dependency("libsemigroups_jll", v"3.5.5"),
    Dependency("CompilerSupportLibraries_jll"),
]

# we want to get notified of any changes to julia_compat, and adapt `version` accordingly
@assert libjulia_min_julia_version <= v"1.10.0"

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"10", julia_compat=libjulia_julia_compat(julia_versions))
