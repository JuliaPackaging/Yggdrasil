# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MDAL"
version = v"0.8.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/lutraconsulting/MDAL/archive/refs/tags/release-$version.tar.gz", "0051495aff910b05d04efa792925cce377920ee02a03a89fa45529fd96cd2953"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/MDAL-*

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/rename-findsqlite-library.patch

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
-DCMAKE_BUILD_TYPE=Release
-DENABLE_TESTS=OFF
-DENABLE_COVERAGE=OFF
-DWITH_HDF5=OFF
-DWITH_GDAL=ON
-DWITH_XML=ON
-DWITH_SQLITE3=ON
-DBUILD_STATIC=OFF
-DBUILD_SHARED=ON
-DBUILD_TOOLS=OFF
-DBUILD_EXTERNAL_DRIVERS=OFF)

#NetCDF is the most restrictive dependency as far as platform availability, so we'll use it where applicable but disable it otherwise
if ! find ${libdir} -name "libnetcdf*.${dlext}" -exec false '{}' +; then
    CMAKE_FLAGS+=(-DWITH_NETCDF=ON)
else
    CMAKE_FLAGS+=(-DWITH_NETCDF=OFF)
fi

cmake . ${CMAKE_FLAGS[@]}
make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libmdal", :libmdal)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GDAL_jll", uuid="a7073274-a066-55f0-b90d-d619367d196c"))
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"))
    Dependency(PackageSpec(name="SQLite_jll", uuid="76ed43ae-9a5d-5a62-8c75-30186b810ce8"))
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3"))
]

# Build the tarballs, and possibly a `build.jl` as well.
#GDAL uses a preferred of 6 so match that
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6")
