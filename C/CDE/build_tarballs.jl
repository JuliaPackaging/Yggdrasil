using BinaryBuilder

name = "CDE"
version = v"1.0.0"
sources = [GitSource("https://github.com/HabershonLab/cde", "049cd0d2da73a0c5bb340ebdb9a78e35348fe49a")]

script = raw"""
cd cde
mkdir -p $bindir
make -j1 EXE="${bindir}/cde${exeext}" COMPILE_STATIC=false 
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

products = [ExecutableProduct("cde", :run_cde)]

dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               preferred_gcc_version=v"6", julia_compat="1.6")
