using BinaryBuilder

name = "Shoco"
version = v"2015.10.8"  # No tagged versions, this is the date of the commit used

sources = [
    GitSource("https://github.com/Ed-von-Schleck/shoco.git",
              "4dee0fc850cdec2bdb911093fe0a6a56e3623b71"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/shoco/
mkdir -p ${libdir}
${CC} shoco.c -o "${libdir}/libshoco.${dlext}" -fPIC -std=c99 -shared
"""

platforms = supported_platforms(; experimental=true)

products = [
    LibraryProduct("libshoco", :libshoco),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
