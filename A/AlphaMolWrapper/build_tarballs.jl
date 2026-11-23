using BinaryBuilder, Pkg

name = "AlphaMolWrapper"
version = v"0.6.1"
julia_versions = [v"1.10", v"1.11", v"1.12"]

sources = [
    GitSource("https://github.com/IvanSpirandelli/AlphaMolWrapper", "ba56dcc8fdcddd955ace4a33f18d897a9ed889fe"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/AlphaMolWrapper
mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DJulia_PREFIX=${prefix}
VERBOSE=ON cmake --build . --target install -- -j${nproc}
install_license ../LICENSE.md
"""
include("../../L/libjulia/common.jl")
julia_compat = libjulia_julia_compat(julia_versions)
platforms = expand_cxxstring_abis(vcat(libjulia_platforms.(julia_versions)...))

products = [
    LibraryProduct("libalphamolwrapper", :libalphamolwrapper),
]

dependencies = [
    BuildDependency(PackageSpec(; name="libjulia_jll", version="1.11.6")),
    Dependency("libcxxwrap_julia_jll"; compat="0.14.8"),
    Dependency("GMP_jll"; compat="6.2.1"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9", julia_compat=julia_compat)
