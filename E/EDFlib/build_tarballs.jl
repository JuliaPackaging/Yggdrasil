using BinaryBuilder

name = "EDFlib"
version = v"1.26.0"

sources = [
    ArchiveSource("https://www.teuniz.net/edflib/edflib_126.tar.gz",
                  "e9e37aa561fa094cb759b4da6d4741f0092d7851a375ee877c18f993150443a8")
]

script = raw"""
cd ${WORKSPACE}/srcdir/edflib*
mkdir -p ${libdir}
mkdir -p ${includedir}
${CC} edflib.c -shared -fPIC -D_LARGEFILE64_SOURCE -D_LARGEFILE_SOURCE -o ${libdir}/libedf.${dlext}
install -Dvm 644 edflib.h ${includedir}/edflib.h
install_license LICENSE
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libedf", :libedf),
    FileProduct("include/edflib.h", :edflib_h)
]

dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
