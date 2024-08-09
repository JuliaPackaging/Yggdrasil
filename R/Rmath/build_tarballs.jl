using BinaryBuilder

name = "Rmath"
version = v"0.4.2"

sources = [
    GitSource("https://github.com/JuliaStats/Rmath-julia.git",
              "18dcd7c259b031c3ce9c275b7dd136585d126017"),
]

script = raw"""
cd $WORKSPACE/srcdir/Rmath-julia*/src
${CC} -shared -fPIC -I../include -std=c99 -DNDEBUG -DMATHLIB_STANDALONE -o libRmath-julia.${dlext} *.c
mkdir -p "${libdir}"
cp libRmath-julia.${dlext} "${libdir}"
"""

platforms = supported_platforms(;experimental=true)

products = [
    LibraryProduct("libRmath-julia", :libRmath),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
