using BinaryBuilder

name = "ShapeLib"
version = v"1.6.3"

sources = [
    ArchiveSource("https://download.osgeo.org/shapelib/shapelib-$(version).tar.gz",
                  "3ff5ead18ca6d2fe249f0e80b361e1ad6782165115268ed4a58c780a60c1e0eb")
]

script = raw"""
cd ${WORKSPACE}/srcdir/shapelib*
autoreconf -fvi
./configure --prefix=${prefix} --host=$target --build=${MACHTYPE} --enable-shared --disable-static
make install
install_license LICENSE-MIT LICENSE-LGPL
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libshp", :libshp),
    ExecutableProduct("csv2shp", :csv2shp),
    ExecutableProduct("dbfadd", :dbfadd),
    ExecutableProduct("dbfcat", :dbfcat),
    ExecutableProduct("dbfcreate", :dbfcreate),
    ExecutableProduct("dbfdump", :dbfdump),
    ExecutableProduct("dbfinfo", :dbfinfo),
    ExecutableProduct("Shape_PointInPoly", :Shape_PointInPoly),
    ExecutableProduct("shpadd", :shpadd),
    ExecutableProduct("shpcat", :shpcat),
    ExecutableProduct("shpcentrd", :shpcentrd),
    ExecutableProduct("shpcreate", :shpcreate),
    ExecutableProduct("shpdata", :shpdata),
    ExecutableProduct("shpdump", :shpdump),
    ExecutableProduct("shpdxf", :shpdxf),
    ExecutableProduct("shpfix", :shpfix),
    ExecutableProduct("shpinfo", :shpinfo),
    ExecutableProduct("shprewind", :shprewind),
    ExecutableProduct("shpsort", :shpsort),
    ExecutableProduct("shptreedump", :shptreedump),
    ExecutableProduct("shputils", :shputils),
    ExecutableProduct("shpwkb", :shpwkb),
    FileProduct("include/shapefil.h", :shapefil_h),
]

dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
