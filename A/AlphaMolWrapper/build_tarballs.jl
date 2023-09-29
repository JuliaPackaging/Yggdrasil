using BinaryBuilder, Pkg

name = "AlphaMolWrapper"
version = v"0.1"
julia_versions = [v"1.7", v"1.8", v"1.9", v"1.10"]
julia_compat = join("~" .* string.(getfield.(julia_versions, :major)) .* "." .* string.(getfield.(julia_versions, :minor)), ", ")

sources = [
    GitSource("https://github.com/IvanSpirandelli/AlphaMolWrapper", "7d27ba6c26eed686a2d82e6e2956dd0ef4a85fd3"),    
]

script = raw"""
cd ${WORKSPACE}/srcdir/AlphaMolWrapper
mkdir build && cd build
cmake .. \
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
    Dependency("GMP_jll"; compat="6.2.1"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9", julia_compat=julia_compat)
