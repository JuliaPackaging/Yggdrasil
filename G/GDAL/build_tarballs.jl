using BinaryBuilder

name = "GDAL"
version = v"3.0.2"

# Collection of sources required to build GDAL
sources = [
    "https://github.com/OSGeo/gdal/releases/download/v$version/gdal-$version.tar.gz" =>
    "787cf150346e58bff0ccf8c131b333139273e35d2abd590ad7196a9ee08f0039",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gdal-*/

# Show options in the log
./configure --help
./configure --prefix=$prefix --host=$target \
    --with-geos=${bindir}/geos-config \
    --with-proj=$prefix \
    --with-libz=$prefix \
    --with-sqlite3=$prefix \
    --with-curl=${bindir}/curl-config \
    --with-python=no \
    --enable-shared \
    --disable-static

make -j${nproc}
make install
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgdal", :libgdal),
    ExecutableProduct("gdal_contour", :gdal_contour_path),
    ExecutableProduct("gdal_grid", :gdal_grid_path),
    ExecutableProduct("gdal_rasterize", :gdal_rasterize_path),
    ExecutableProduct("gdal_translate", :gdal_translate_path),
    ExecutableProduct("gdaladdo", :gdaladdo_path),
    ExecutableProduct("gdalbuildvrt", :gdalbuildvrt_path),
    ExecutableProduct("gdaldem", :gdaldem_path),
    ExecutableProduct("gdalinfo", :gdalinfo_path),
    ExecutableProduct("gdallocationinfo", :gdallocationinfo_path),
    ExecutableProduct("gdalmanage", :gdalmanage_path),
    ExecutableProduct("gdalsrsinfo", :gdalsrsinfo_path),
    ExecutableProduct("gdaltindex", :gdaltindex_path),
    ExecutableProduct("gdaltransform", :gdaltransform_path),
    ExecutableProduct("gdalwarp", :gdalwarp_path),
    ExecutableProduct("nearblack", :nearblack_path),
    ExecutableProduct("ogr2ogr", :ogr2ogr_path),
    ExecutableProduct("ogrinfo", :ogrinfo_path),
    ExecutableProduct("ogrlineref", :ogrlineref_path),
    ExecutableProduct("ogrtindex", :ogrtindex_path),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "GEOS_jll",
    "PROJ_jll",
    "Zlib_jll",
    "SQLite_jll",
    "LibCURL_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
