using BinaryBuilder, Pkg

name = "AlphaMolWrapper"
version = v"0.1"
julia_versions = [v"1.7", v"1.8", v"1.9", v"1.10"]

sources = [
    GitSource("https://github.com/IvanSpirandelli/AlphaMolWrapper", "4d7e902a7bec19a7cc3df905b7900afb75e8e26a"),    
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
