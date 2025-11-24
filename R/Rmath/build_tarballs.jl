using BinaryBuilder

name = "Rmath"
version = v"0.5.1"

sources = [
    GitSource("https://github.com/JuliaStats/Rmath-julia.git",
              "6f2d37ff112914d65559bc3e0035b325c11cf361"),
]

script = raw"""
cd $WORKSPACE/srcdir/Rmath-julia/src
make -j${nproc}
install -Dvm 755 libRmath-julia.${dlext} -t ${libdir}
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libRmath-julia", :libRmath),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6", preferred_gcc_version=v"6")
