# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

julia_version = v"1.6.0"

name = "YosysWrapper"
version = v"0.9.0"

# Collection of sources required to complete build
sources = [
    DirectorySource("./src"),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Yosys_jll", compat="0.9.0"),
    Dependency("libcxxwrap_julia_jll"),
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version)),
]


# Bash recipe for building across all platforms
script = raw"""
mkdir -p build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DJulia_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
cmake --build . --config Release --target install -- -j${nproc}
"""

include("../../L/libjulia/common.jl")
platforms = libjulia_platforms(julia_version)
platforms = filter!(p -> Sys.islinux(p), platforms)
platforms = expand_cxxstring_abis(platforms)
# building for CXX03 string ABI doesn't work with boost
filter!(x -> cxxstring_abi(x) != "cxx03", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libyosyswrapper", :libyosyswrapper),
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
