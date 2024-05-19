using BinaryBuilder

name = "Rmath"
version = v"0.4.2"

sources = [
    GitSource("https://github.com/JuliaStats/Rmath-julia.git",
              "18dcd7c259b031c3ce9c275b7dd136585d126017"),
]

script = raw"""
cd $WORKSPACE/srcdir/Rmath-julia*
make -j${nproc}
mkdir -p "${libdir}"
mv src/libRmath-julia.* "${libdir}"
"""

platforms = supported_platforms(;experimental=true)

products = [
    LibraryProduct("libRmath-julia", :libRmath),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
