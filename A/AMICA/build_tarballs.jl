using BinaryBuilder

name = "AMICA"
version = v"2021.3.24"  # AMICA has no tagged versions

sources = [
    GitSource("https://github.com/japalmer29/amica.git",
              "b4328096805826c3fcc228ca71561027968b10ae"),
]

script = raw"""
mkdir -p ${bindir}
cd ${WORKSPACE}/srcdir/amica*
mpif90 -O3 amica15.f90 funmod2.f90 -o ${bindir}/amica
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("amica", :amica),
]

dependencies = [
    Dependency("MPICH_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
