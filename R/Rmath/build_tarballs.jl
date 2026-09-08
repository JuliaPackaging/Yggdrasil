using BinaryBuilder

name = "Rmath"
version = v"0.5.2"

sources = [
    GitSource("https://github.com/JuliaStats/Rmath-julia.git",
              "982eb93bca6b655d8b433af23ee847561694e2b2"),
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
