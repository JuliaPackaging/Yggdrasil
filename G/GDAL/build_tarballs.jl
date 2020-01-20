using BinaryBuilder

name = "GDAL"
version = v"3.0.3"

# Collection of sources required to build GDAL
sources = [
    "https://github.com/OSGeo/gdal/releases/download/v$version/gdal-$version.tar.gz" =>
    "fe9bbe1cd4f74a4917dec9585a91d9018d3a3b61e379aa9a1b709e278dde11d6",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gdal-*/

if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L${libdir}"
    # Apply patch to customise PROJ library
    atomic_patch -p1 "$WORKSPACE/srcdir/patches/configure_ac_proj_libs.patch"
    autoreconf -vi
    export PROJ_LIBS="proj_6_3"
elif [[ "${target}" == powerpc64le-* ]]; then
    # Need to remember to link against libpthread and libdl
    export LDFLAGS="-lpthread -ldl"
fi

# Clear out `.la` files since they're often wrong and screw us up
rm -f ${prefix}/lib/*.la

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
platforms = expand_cxxstring_abis(platforms)

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
