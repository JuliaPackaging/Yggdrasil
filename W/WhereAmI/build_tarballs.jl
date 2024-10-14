using BinaryBuilder

name = "WhereAmI"
version = v"1.0.0"  # no proper versions/releases, this is made up

sources = [
    GitSource("https://github.com/gpakosz/whereami",
              "dcb52a058dc14530ba9ae05e4339bd3ddfae0e0e"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/whereami/
mkdir -p "${libdir}"
FLAGS=(-Isrc -O2 -std=c99 -fPIC)
if [[ "${target}" == *-gnu* ]]; then
    FLAGS+=(-ldl)
fi
cc src/whereami.c ${FLAGS[@]} -shared -o "${libdir}/libwai.${dlext}"
install -Dvm 644 src/whereami.h "${includedir}/whereami.h"
install_license LICENSE.MIT
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libwai", :libwai),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
