using BinaryBuilder, Pkg

name = "PROJ"
version = v"7.2.0"

# Collection of sources required to build PROJ
sources = [
    ArchiveSource("https://download.osgeo.org/proj/proj-$version.tar.gz",
        "2957798e5fe295ff96a2af1889d0428e486363d210889422f76dd744f7885763"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/proj-*/

# sqlite needed to build proj.db, so this should not be the
# cross-compiled one since it needs to be executed on the host
apk add sqlite
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
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_TESTING=OFF \
      -DSQLITE3_INCLUDE_DIR=$prefix/include \
      -DSQLITE3_LIBRARY=$SQLITE3_LIBRARY \
      -DCURL_INCLUDE_DIR=$prefix/include \
      -DCURL_LIBRARY=$CURL_LIBRARY \
      -DTIFF_INCLUDE_DIR=$prefix/include \
      -DTIFF_LIBRARY_RELEASE=$TIFF_LIBRARY_RELEASE \
      ..
make -j${nproc}
make install
"""

platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libproj", "libproj_$(version.major)_$(version.minor)"], :libproj),

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
    Dependency(PackageSpec(name="SQLite_jll", uuid="76ed43ae-9a5d-5a62-8c75-30186b810ce8")),
    Dependency(PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828")),
    # libcurl changed compatibility version for macOS from v7.71 to v7.73 (v11
    # to v12)
    Dependency(PackageSpec(name="LibCURL_jll", uuid="deac9b47-8bc7-5906-a0fe-35ac56dc84c0"), v"7.71.1"),
    # The following libraries are dependencies of LibCURL_jll which is now a
    # stdlib, but the stdlib doesn't explicitly list its dependencies
    Dependency("LibSSH2_jll"),
    Dependency("MbedTLS_jll"),
    Dependency("nghttp2_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
