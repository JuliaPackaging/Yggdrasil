using BinaryBuilder

name = "Rmath"
version = v"0.2.2"

sources = [
    ArchiveSource("https://github.com/JuliaStats/Rmath-julia/archive/v$(version).tar.gz",
                  "6544f40e51999469873b0f28d4bdeecdc847d4b24250a65027ae07e7dccb9ccd"),
]

script = raw"""
cd $WORKSPACE/srcdir/Rmath-julia-*
make
mkdir -p "${libdir}"
mv src/libRmath-julia.* "${libdir}"
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libRmath-julia", :libRmath),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
