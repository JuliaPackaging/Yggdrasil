using BinaryBuilder

name = "Shoco"
version = v"2015.10.8"  # No tagged versions, this is the date of the commit used

sources = [
    GitSource("https://github.com/Ed-von-Schleck/shoco.git",
              "4dee0fc850cdec2bdb911093fe0a6a56e3623b71"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/shoco-*
if [[ ${target} == *apple* ]]; then
    flag=-dynamiclib
else
    flag=-shared
fi
${CC} shoco.c -o libshoco.${dlext} -fPIC -std=c99 ${flag}
if [ ! -d ${prefix}/lib ]; then
    mkdir -p ${prefix}/lib
fi
cp libshoco.* ${prefix}/lib
"""

platforms = supported_platforms(; experimental=true)

products = [
    LibraryProduct("libshoco", :libshoco),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
