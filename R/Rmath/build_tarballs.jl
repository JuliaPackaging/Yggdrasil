using BinaryBuilder

name = "Rmath"
version = v"0.2.2"

sources = [
    GitSource("https://github.com/JuliaStats/Rmath-julia.git",
              "80bc99724807e0ad1c46800d8497480bd5f110cb"),
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
