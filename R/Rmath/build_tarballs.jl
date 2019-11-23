using BinaryBuilder

name = "Rmath"
version = v"0.2.2"

sources = [
    "https://github.com/JuliaStats/Rmath-julia/archive/$(version).tar.gz" =>
        "6544f40e51999469873b0f28d4bdeecdc847d4b24250a65027ae07e7dccb9ccd",
]

script = raw"""
cd $WORKSPACE/srcdir/Rmath-julia-*
make
if [[ ${target} == *-mingw32 ]]; then
    OUTDIR=$DESTDIR/bin
else
    OUTDIR=$DESTDIR/lib
fi
mkdir -p $OUTDIR
mv src/libRmath-julia.* $OUTDIR
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libRmath-julia", :libRmath),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
