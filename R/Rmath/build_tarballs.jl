using BinaryBuilder

name = "Rmath"
version = v"0.3.0"

sources = [
    GitSource("https://github.com/JuliaStats/Rmath-julia.git",
              "c71948a8ce7b8b1aca7b94a3e97840bc06c51749"),
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
