# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libspatialite"
version = v"5.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.gaia-gis.it/gaia-sins/libspatialite-$(version).tar.gz", "eecbc94311c78012d059ebc0fae86ea5ef6eecb13303e6e82b3753c1b3409e98")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/libspatialite-*

export CPPFLAGS="-I${includedir}"

update_configure_scripts

./configure \
--prefix=${prefix} \
--build=${MACHTYPE} \
--host=${target} \
--includedir=${includedir} \
--libdir=${libdir} \
--enable-shared=yes \
--enable-static=no \
--enable-geocallbacks=yes \
--enable-knn=yes \
--enable-proj=yes \
--enable-iconv=yes \
--enable-freexl=no \
--enable-epsg=yes \
--enable-geos=yes \
--enable-geosadvanced=yes \
--enable-geosreentrant=yes \
--enable-geos370=yes \
--enable-gcp=no \
--enable-rttopo=no \
--enable-libxml2=yes \
--enable-minizip=no \
--enable-geopackage=yes \
--enable-gcov=no \
--enable-examples=no \
--enable-module-only=no

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))


# The products that we will ensure are always built
products = [
    LibraryProduct("mod_spatialite", :mod_spatialite),
    LibraryProduct("libspatialite", :libspatialite)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("SQLite_jll")
    Dependency(PackageSpec(name="GEOS_jll", uuid="d604d12d-fa86-5845-992e-78dc15976526"))
    Dependency(PackageSpec(name="PROJ_jll", uuid="58948b4f-47e0-5654-a9ad-f609743f8632"))
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
#GEOS uses preferred of 6, so match that here
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6")
