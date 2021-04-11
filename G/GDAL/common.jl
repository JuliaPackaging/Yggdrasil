using BinaryBuilder, Pkg

function configure(version_offset, min_julia_version, proj_jll_version)
    # The version of this JLL is decoupled from the upstream version.
    # Whenever we package a new upstream release, we initially map its
    # version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
    # So for example version 2.6.3 would become 200.600.300.

    name = "GDAL"
    upstream_version = v"3.2.1"
    version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                            upstream_version.minor * 100 + version_offset.minor,
                            upstream_version.patch * 100 + version_offset.patch)

    # Collection of sources required to build GDAL
    sources = [
        ArchiveSource("https://github.com/OSGeo/gdal/releases/download/v$upstream_version/gdal-$upstream_version.tar.gz",
            "43d40ba940e3927e38f9e98062ff62f9fa993ceade82f26f16fab7e73edb572e"),
        DirectorySource("../bundled"),
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
        Dependency(PackageSpec(name="PROJ_jll", version=proj_jll_version)),
        Dependency("Zlib_jll"),
        Dependency("SQLite_jll"),
        Dependency("OpenJpeg_jll"),
        Dependency("Expat_jll"),
        Dependency("Zstd_jll"),
        Dependency("Libtiff_jll"),
        Dependency("libgeotiff_jll"),
    ]

    jll_stdlibs = Dict(
        v"1.3" => [
            Dependency("LibCURL_jll", v"7.71.1"),
            # The following libraries are dependencies of LibCURL_jll which is now a
            # stdlib, but the stdlib doesn't explicitly list its dependencies
            Dependency("LibSSH2_jll", v"1.9.0"),
            Dependency("MbedTLS_jll", v"2.16.8"),
            Dependency("nghttp2_jll", v"1.40.0"),
        ],
        v"1.6" => [
            Dependency("LibCURL_jll"),
            # The following libraries are dependencies of LibCURL_jll which is now a
            # stdlib, but the stdlib doesn't explicitly list its dependencies
            Dependency("LibSSH2_jll"),
            Dependency("MbedTLS_jll", v"2.24.0"),
            Dependency("nghttp2_jll"),
        ]
    )

    append!(dependencies, jll_stdlibs[min_julia_version])
    
    return name, version, sources, script, platforms, products, dependencies
end
