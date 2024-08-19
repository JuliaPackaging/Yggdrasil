using BinaryBuilder

name = "Rmath"
version = v"0.5.0"

sources = [
    GitSource("https://github.com/JuliaStats/Rmath-julia.git",
              "ca7518b9b66320a592c9a2a15663af99ca55e45f"),
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
