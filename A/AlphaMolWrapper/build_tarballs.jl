using BinaryBuilder, Pkg

name = "AlphaMolWrapper"
version = v"0.5.0"
julia_versions = [v"1.7", v"1.8", v"1.9", v"1.10", v"1.11"]
julia_compat = join("~" .* string.(getfield.(julia_versions, :major)) .* "." .* string.(getfield.(julia_versions, :minor)), ", ")


sources = [
    GitSource("https://github.com/IvanSpirandelli/AlphaMolWrapper", "e3e0dd706b6bad98d5c58b96e0a9fc6b5fb7a2a3"),    
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
    Dependency("libcxxwrap_julia_jll"; compat="0.11.2"),
    Dependency("GMP_jll"; compat="6.2.1"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9", julia_compat=julia_compat)
