# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
import BinaryBuilderBase: nbits

julia_version = v"1.5.3"

name = "ConnectFourSolver"
version = v"0.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/findmyway/connect4.git", "d84c8a48b6c2d2cabe0a780d51758980f8084992"),
]

# Bash recipe for building across all platforms
script = raw"""
cd connect4*

install_license LICENSE
mkdir build
cd build
cmake \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix} \
    ..
VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = libjulia_platforms(julia_version)
platforms = expand_cxxstring_abis(platforms)
filter!(p -> nbits(p) != 32, platforms) # code use __int128 which is not available on 32bit targets

# The products that we will ensure are always built
products = [
    LibraryProduct("libconnect4jl", :libconnect4jl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version)),
    Dependency("libcxxwrap_julia_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"8",
    julia_compat = "$(julia_version.major).$(julia_version.minor)")
