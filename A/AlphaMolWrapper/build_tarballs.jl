using BinaryBuilder, Pkg

name = "AlphaMolWrapper"
version = v"0.4.0"

sources = [
    GitSource("https://github.com/IvanSpirandelli/AlphaMolWrapper", "9b37921dd2af32574151f42bb05e1dc9425300ec"),    
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
    preferred_gcc_version=v"9", julia_compat="1.7")
