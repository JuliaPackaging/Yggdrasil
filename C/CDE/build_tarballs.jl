using BinaryBuilder

name = "CDE"
version = v"1.0.0"
sources = [GitSource("https://github.com/HabershonLab/cde", "049cd0d2da73a0c5bb340ebdb9a78e35348fe49a")]

script = raw"""
export LDFLAGS="-L${libdir}"
cd cde
gfortran -O3 -c src/constants.f90 -o src/constants.o -J src
gfortran -O3 -c src/globaldata.f90 -o src/globaldata.o -J src
gfortran -O3 -c src/functions.f90 -o src/functions.o -J src
gfortran -O3 -c src/io.f90 -o src/io.o -J src
gfortran -O3 -c src/structure.f90 -o src/structure.o -J src
gfortran -O3 -c src/pes.f90 -o src/pes.o -J src
gfortran -O3 -c src/rpath.f90 -o src/rpath.o -J src
gfortran -O3 -c src/pathopt.f90 -o src/pathopt.o -J src
gfortran -O3 -c src/pathfinder.f90 -o src/pathfinder.o -J src
gfortran -O3 -c src/main.f90 -o src/main.o -J src
mkdir $bindir
gfortran -O3 -o "${bindir}/cde_exe" src/constants.o src/globaldata.o src/functions.o src/io.o src/structure.o src/pes.o src/rpath.o src/pathopt.o src/pathfinder.o src/main.o -L"${libdir}" -lopenblas
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

products = [ExecutableProduct("cde_exe", :cde, "bin")]

dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
