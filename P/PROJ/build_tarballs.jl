using BinaryBuilder

name = "PROJ"
version = v"6.2.1"

# Collection of sources required to build PROJ
sources = [
    "https://download.osgeo.org/proj/proj-$version.tar.gz" =>
    "7f2e0fe63312f1e766057cceb53dc9585c4a335ff6641de45696dbd40d17c340",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/proj-*/

# sqlite needed to build proj.db, so this should not be the
# cross-compiled one since it needs to be executed on the host
apk add sqlite

if [[ ${target} == *mingw* ]]; then
    SQLITE3_LIBRARY=${libdir}/libsqlite3-0.dll
else
    SQLITE3_LIBRARY=${libdir}/libsqlite3.${dlext}
fi

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DSQLITE3_INCLUDE_DIR=$prefix/include \
      -DSQLITE3_LIBRARY=$SQLITE3_LIBRARY \
      -DHAVE_PTHREAD_MUTEX_RECURSIVE_DEFN=1 \
      -DBUILD_LIBPROJ_SHARED=ON \
      ..
cmake --build .
make install

# add proj-datumgrid files directly to the result
wget https://download.osgeo.org/proj/proj-datumgrid-1.8.tar.gz
tar xzf proj-datumgrid-1.8.tar.gz -C $prefix/share/proj/
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libproj", :libproj),

    ExecutableProduct("cct", :cct_path),
    ExecutableProduct("cs2cs", :cs2cs_path),
    ExecutableProduct("geod", :geod_path),
    ExecutableProduct("gie", :gie_path),
    ExecutableProduct("proj", :proj_path),
    ExecutableProduct("projinfo", :projinfo_path),

    # complete contents of share/proj, must be kept up to date
    FileProduct(joinpath("share", "proj", "CH"), :ch_path),
    FileProduct(joinpath("share", "proj", "GL27"), :gl27_path),
    FileProduct(joinpath("share", "proj", "ITRF2000"), :itrf2000_path),
    FileProduct(joinpath("share", "proj", "ITRF2008"), :itrf2008_path),
    FileProduct(joinpath("share", "proj", "ITRF2014"), :itrf2014_path),
    FileProduct(joinpath("share", "proj", "nad.lst"), :nad_lst_path),
    FileProduct(joinpath("share", "proj", "nad27"), :nad27_path),
    FileProduct(joinpath("share", "proj", "nad83"), :nad83_path),
    FileProduct(joinpath("share", "proj", "null"), :null_path),
    FileProduct(joinpath("share", "proj", "other.extra"), :other_extra_path),
    FileProduct(joinpath("share", "proj", "proj.db"), :proj_db_path),
    FileProduct(joinpath("share", "proj", "world"), :world_path),

    # part of files from proj-datumgrid which are added to the default ones
    # all are added but only the few below are checked if they are added
    # note that none of proj-datumgrid-europe, proj-datumgrid-north-america,
    # proj-datumgrid-oceania, proj-datumgrid-world is added by default,
    # though users are free to add them to the rest themselves
    FileProduct(joinpath("share", "proj", "alaska"), :alaska_path),
    FileProduct(joinpath("share", "proj", "conus"), :conus_path),
    FileProduct(joinpath("share", "proj", "egm96_15.gtx"), :egm96_15_path),
    FileProduct(joinpath("share", "proj", "ntv1_can.dat"), :ntv1_can_path),
]

# Dependencies that must be installed before this package can be built
dependencies = ["SQLite_jll"]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
