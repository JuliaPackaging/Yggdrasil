using BinaryBuilder, Pkg

function configure(version_offset, min_julia_version)
    # The version of this JLL is decoupled from the upstream version.
    # Whenever we package a new upstream release, we initially map its
    # version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
    # So for example version 2.6.3 would become 200.600.300.

    name = "PROJ"
    upstream_version = v"7.2.1"
    version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                            upstream_version.minor * 100 + version_offset.minor,
                            upstream_version.patch * 100 + version_offset.patch)

    # Collection of sources required to build PROJ
    sources = [
        ArchiveSource("https://download.osgeo.org/proj/proj-$upstream_version.tar.gz",
            "b384f42e5fb9c6d01fe5fa4d31da2e91329668863a684f97be5d4760dbbf0a14"),
    ]

    # Bash recipe for building across all platforms
    script = raw"""
    cd $WORKSPACE/srcdir/proj-*/

    # Get rid of target sqlite3, to avoid it's picked up by the build system
    rm "${bindir}/sqlite3${exeext}"

    if [[ ${target} == *mingw* ]]; then
        SQLITE3_LIBRARY=${libdir}/libsqlite3-0.dll
        CURL_LIBRARY=${libdir}/libcurl-4.dll
        TIFF_LIBRARY_RELEASE=${libdir}/libtiff-5.dll
    else
        SQLITE3_LIBRARY=${libdir}/libsqlite3.${dlext}
        CURL_LIBRARY=${libdir}/libcurl.${dlext}
        TIFF_LIBRARY_RELEASE=${libdir}/libtiff.${dlext}
    fi

    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTING=OFF \
        -DSQLITE3_INCLUDE_DIR=${includedir} \
        -DSQLITE3_LIBRARY=$SQLITE3_LIBRARY \
        -DCURL_INCLUDE_DIR=${includedir} \
        -DCURL_LIBRARY=$CURL_LIBRARY \
        -DTIFF_INCLUDE_DIR=${includedir} \
        -DTIFF_LIBRARY_RELEASE=$TIFF_LIBRARY_RELEASE \
        ..
    make -j${nproc}
    make install
    """

    platforms = expand_cxxstring_abis(supported_platforms())

    # The products that we will ensure are always built
    products = [
        LibraryProduct(["libproj", "libproj_$(upstream_version.major)_$(upstream_version.minor)"], :libproj),

        # Excecutables
        ExecutableProduct("cct", :cct),
        ExecutableProduct("cs2cs", :cs2cs),
        ExecutableProduct("geod", :geod),
        ExecutableProduct("gie", :gie),
        ExecutableProduct("proj", :proj),
        ExecutableProduct("projinfo", :projinfo),
        ExecutableProduct("projsync", :projsync),

        # complete contents of share/proj, must be kept up to date
        FileProduct(joinpath("share", "proj", "CH"), :ch),
        FileProduct(joinpath("share", "proj", "GL27"), :gl27),
        FileProduct(joinpath("share", "proj", "ITRF2000"), :itrf2000),
        FileProduct(joinpath("share", "proj", "ITRF2008"), :itrf2008),
        FileProduct(joinpath("share", "proj", "ITRF2014"), :itrf2014),
        FileProduct(joinpath("share", "proj", "nad.lst"), :nad_lst),
        FileProduct(joinpath("share", "proj", "nad27"), :nad27),
        FileProduct(joinpath("share", "proj", "nad83"), :nad83),
        FileProduct(joinpath("share", "proj", "other.extra"), :other_extra),
        FileProduct(joinpath("share", "proj", "proj.db"), :proj_db),
        FileProduct(joinpath("share", "proj", "proj.ini"), :proj_ini),
        FileProduct(joinpath("share", "proj", "world"), :world),
    ]

    # Dependencies that must be installed before this package can be built
    dependencies = [
        # Host SQLite needed to build proj.db
        HostBuildDependency("SQLite_jll"),
        Dependency("SQLite_jll"),
        Dependency("Libtiff_jll"),
        Dependency("Zlib_jll"),
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

    # Build the tarballs, and possibly a `build.jl` as well.
    return name, version, sources, script, platforms, products, dependencies
end
