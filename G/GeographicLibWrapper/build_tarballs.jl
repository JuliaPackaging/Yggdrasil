# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GeographicLibWrapper"
version = v"0.1.0"

julia_version = v"1.6"

sources = [DirectorySource("./src")]

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
platforms = expand_cxxstring_abis(libjulia_platforms(julia_version))

products = [LibraryProduct("libGeographicLibWrapper", :libGeographicLibWrapper)]

dependencies = [
    Dependency("GeographicLib_jll"),
    Dependency("libcxxwrap_julia_jll"),
    BuildDependency(PackageSpec(; name="libjulia_jll", version=julia_version)),
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version=v"7",
)
