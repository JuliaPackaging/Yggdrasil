using BinaryBuilder

name = "GDAL"
version = v"3.0.4"

# Collection of sources required to build GDAL
sources = [
    ArchiveSource("https://github.com/OSGeo/gdal/releases/download/v$version/gdal-$version.tar.gz",
        "fc15d2b9107b250305a1e0bd8421dd9ec1ba7ac73421e4509267052995af5e83"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gdal-*/

if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L${libdir}"
    # Apply patch to customise PROJ library
    atomic_patch -p1 "$WORKSPACE/srcdir/patches/configure_ac_proj_libs.patch"
    autoreconf -vi
    export PROJ_LIBS="proj_7_0"
elif [[ "${target}" == *-linux-* ]]; then
    # Make sure GEOS is linked against libstdc++
     atomic_patch -p1 "$WORKSPACE/srcdir/patches/geos-m4-extra-libs.patch"
     atomic_patch -p1 "$WORKSPACE/srcdir/patches/configure_ac_curl_libs.patch"
    export EXTRA_GEOS_LIBS="-lstdc++"
    export EXTRA_CURL_LIBS="-lstdc++"
    export LDFLAGS="$LDFLAGS -lstdc++"
    if [[ "${target}" == powerpc64le-* ]]; then
        atomic_patch -p1 "$WORKSPACE/srcdir/patches/sqlite3-m4-extra-libs.patch"
        export EXTRA_GEOS_LIBS="${EXTRA_GEOS_LIBS} -lm"
        export EXTRA_SQLITE3_LIBS="-lm"
        # libpthread and libldl are needed for libgdal, so let's always use them
        export LDFLAGS="$LDFLAGS -lpthread -ldl"
    fi
    autoreconf -vi
fi

# Clear out `.la` files since they're often wrong and screw us up
rm -f ${prefix}/lib/*.la

./configure --help
./configure --prefix=$prefix --host=$target \
    --with-geos=${bindir}/geos-config \
    --with-proj=$prefix \
    --with-libz=$prefix \
    --with-expat=$prefix \
    --with-zstd=$prefix \
    --with-webp=$prefix \
    --with-sqlite3=$prefix \
    --with-curl=${bindir}/curl-config \
    --with-openjpeg \
    --with-python=no \
    --enable-shared \
    --disable-static
# Make sure that some important libraries are found
grep "HAVE_GEOS='yes'" config.log
grep "HAVE_SQLITE='yes'" config.log
grep "CURL_SETTING='yes'" config.log
grep "ZSTD_SETTING='yes'" config.log
grep "HAVE_EXPAT='yes'" config.log

make -j${nproc}
make install
"""

platforms = expand_cxxstring_abis(supported_platforms())

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
    Dependency("GEOS_jll"),
    Dependency("PROJ_jll"),
    Dependency("Zlib_jll"),
    Dependency("SQLite_jll"),
    Dependency("LibCURL_jll"),
    Dependency("OpenJpeg_jll"),
    Dependency("Expat_jll"),
    Dependency("Zstd_jll"),
    Dependency("libwebp_jll"),
    # The following libraries are dependencies of LibCURL_jll which is now a
    # stdlib, but the stdlib doesn't explicitly list its dependencies
    Dependency("LibSSH2_jll"),
    Dependency("MbedTLS_jll"),
    Dependency("nghttp2_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
