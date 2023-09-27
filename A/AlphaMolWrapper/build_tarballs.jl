using BinaryBuilder, Pkg

name = "AlphaMolWrapper"
version = v"0.1"
julia_versions = [v"1.7", v"1.8", v"1.9", v"1.10"]

sources = [
    GitSource("https://github.com/IvanSpirandelli/AlphaMolWrapper", "a13beb3ffe986c3f493ca88212c5c9ed2b705225"),    
]

script = raw"""
cd ${WORKSPACE}/srcdir/AlphaMolWrapper
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix} 
VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
"""
include("../../L/libjulia/common.jl")
platforms = expand_cxxstring_abis(vcat(libjulia_platforms.(julia_versions)...))

products = [
    LibraryProduct("libalphamolwrapper", :libalphamolwrapper),
]

dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"),
    Dependency("GMP_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"11", julia_compat="1.7")
