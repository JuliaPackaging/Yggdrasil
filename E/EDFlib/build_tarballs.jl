using BinaryBuilder

name = "EDFlib"
version = v"1.16.0"

sources = [
    ArchiveSource("https://www.teuniz.net/edflib/edflib_116.tar.gz",
                  "cc9f9cc63869fa5742a7dd7e1aa3ff69fedcd4547f2c56ada43d4a4bfa4c6a4e";
                  unpack_target="edflib")
]

script = raw"""
cd ${WORKSPACE}/srcdir/edflib
mkdir ${libdir}
${CC} edflib.c -shared -fPIC -D_LARGEFILE64_SOURCE -D_LARGEFILE_SOURCE -o ${libdir}/libedflib.${dlext}
# No separate license file, it just lives in the README and in the source files
install_license README.md
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libedflib", :libedflib)
]

dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
