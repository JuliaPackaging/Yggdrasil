# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GDAL"
upstream_version = v"3.5.0"
version_offset = v"0.0.0"
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to build GDAL
sources = [
    ArchiveSource("https://github.com/OSGeo/gdal/releases/download/v$upstream_version/gdal-$upstream_version.tar.gz",
        "3affc513b8aa5a76b996eca55f45cb3e32acacf4a262ce4f686d4c8bba7ced40"),
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
    export PROJ_LIBS="proj_9_0"
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

# same fix as used for PROJ
if [[ "${target}" == x86_64-linux-musl* ]]; then
    export LDFLAGS="$LDFLAGS -lcurl"
fi

# Clear out `.la` files since they're often wrong and screw us up
rm -f ${prefix}/lib/*.la

# Read the options in the log file
./configure --help

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
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

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
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
    Dependency("GEOS_jll"; compat="~3.10"),
    Dependency("PROJ_jll"; compat="~900.0"),
    Dependency("Zlib_jll"),
    Dependency("SQLite_jll"),
    Dependency("OpenJpeg_jll"),
    Dependency("Expat_jll"; compat="2.2.10"),
    Dependency("Zstd_jll"),
    Dependency("Libtiff_jll"; compat="4.3"),
    Dependency("libgeotiff_jll"; compat="1.7.1"),
    Dependency("LibCURL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")
