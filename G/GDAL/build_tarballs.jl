using BinaryBuilder, Pkg

name = "GDAL"
version = v"3.2.0"

# Collection of sources required to build GDAL
sources = [
    ArchiveSource("https://github.com/OSGeo/gdal/releases/download/v$version/gdal-$version.tar.gz",
        "66dbab444f9fad113245cef241e52c4ab3e1f315e59759820e16a67e94931347"),
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
    export PROJ_LIBS="proj_7_2"
elif [[ "${target}" == *-linux-* ]]; then
    # Hint to find libstdc++, required to link against C++ libs when using C compiler
    if [[ "${nbits}" == 32 ]]; then
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib"
    else
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64"
    fi
    # Use same flags also for GEOS
    atomic_patch -p1 "$WORKSPACE/srcdir/patches/geos-m4-extra-cflags.patch"
    export EXTRA_GEOS_CFLAGS="${CFLAGS}"
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
    --with-tiff=$prefix \
    --with-geotiff=$prefix \
    --with-libz=$prefix \
    --with-expat=$prefix \
    --with-zstd=$prefix \
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
    # fix to minor PROJ version; also update PROJ_LIBS above
    # needed for Windows because of https://github.com/OSGeo/PROJ/blob/949171a6e/cmake/ProjVersion.cmake#L40-L46
    # to avoid this problem https://github.com/JuliaGeo/GDAL.jl/pull/102
    Dependency(PackageSpec(name="PROJ_jll", version="7.2")),
    Dependency("Zlib_jll"),
    Dependency("SQLite_jll"),
    Dependency("LibCURL_jll", v"7.71.1"),
    Dependency("OpenJpeg_jll"),
    Dependency("Expat_jll"),
    Dependency("Zstd_jll"),
    Dependency("Libtiff_jll"),
    Dependency("libgeotiff_jll"),
    # The following libraries are dependencies of LibCURL_jll which is now a
    # stdlib, but the stdlib doesn't explicitly list its dependencies
    Dependency("LibSSH2_jll", v"1.9.0"),
    Dependency("MbedTLS_jll", v"2.16.8"),
    Dependency("nghttp2_jll", v"1.40.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
