using BinaryBuilder

name = "CDE"
version = v"1.0.2"
sources = [GitSource("https://github.com/HabershonLab/cde", "ac632896a99b284d96eb6bfb66bf48068acac209")]

script = raw"""
cd cde
mkdir -p $bindir
make -j${nproc} EXE="${bindir}/cde${exeext}"
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
