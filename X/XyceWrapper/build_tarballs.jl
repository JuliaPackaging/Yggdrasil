# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

julia_versions = [v"1.6.3", v"1.7"]

name = "XyceWrapper"
version = v"0.2.0"

# Collection of sources required to complete build
sources = [
    DirectorySource("./src"),
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
install_license /usr/share/licenses/MIT
"""

include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libxycelib", :xycelib),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Xyce_jll"; compat="^7.4.0"),
    Dependency("libcxxwrap_julia_jll"),
    BuildDependency("libjulia_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6", preferred_gcc_version=v"7")
