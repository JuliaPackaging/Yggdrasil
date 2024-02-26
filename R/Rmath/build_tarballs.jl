using BinaryBuilder

name = "Rmath"
version = v"0.4.0"

sources = [
    GitSource("https://github.com/JuliaStats/Rmath-julia.git",
              "be5aaa48f9c40361e4f4235bf39b0826f3633197"),
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
