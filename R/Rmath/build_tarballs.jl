using BinaryBuilder

name = "Rmath"
version = v"0.4.3"

sources = [
    GitSource("https://github.com/JuliaStats/Rmath-julia.git",
              "d560159af0a388d8afaf19f7bf2efc51afcf53d9"),
]

script = raw"""
cd $WORKSPACE/srcdir/Rmath-julia
make -j${nproc} CC=${CC}
cp -p libRmath-julia.${dlext} ${libdir}
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libRmath-julia", :libRmath),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
