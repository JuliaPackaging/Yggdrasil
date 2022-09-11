# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GDAL"
upstream_version = v"3.5.1"
version_offset = v"0.0.1"
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
    upstream_version.minor * 100 + version_offset.minor,
    upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to build GDAL
sources = [
    ArchiveSource("https://github.com/OSGeo/gdal/releases/download/v$upstream_version/gdal-$upstream_version.tar.gz",
        "7c4406ca010dc8632703a0a326f39e9db25d9f1f6ebaaeca64a963e3fac123d1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gdal-*/
mkdir build
cd build

if [[ "${target}" == *-freebsd* ]]; then
    # Our FreeBSD libc has `environ` as undefined symbol, so the linker will
    # complain if this symbol is used in the built library, even if this won't
    # be a problem at runtime. This flag allows having undefined symbols.
    export LDFLAGS="-undefined"
fi

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix}
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
-DCMAKE_PREFIX_PATH=${prefix}
-DCMAKE_FIND_ROOT_PATH=${prefix}
-DCMAKE_BUILD_TYPE=Release
-DBUILD_PYTHON_BINDINGS=OFF
-DBUILD_JAVA_BINDINGS=OFF
-DBUILD_CSHARP_BINDINGS=OFF
-DGDAL_USE_CURL=ON
-DGDAL_USE_EXPAT=ON
-DGDAL_USE_GEOTIFF=ON
-DGDAL_USE_GEOS=ON
-DGDAL_USE_OPENJPEG=ON
-DGDAL_USE_SQLITE3=ON
-DGDAL_USE_TIFF=ON
-DGDAL_USE_ZLIB=ON
-DGDAL_USE_ZSTD=ON)

# NetCDF is the most restrictive dependency as far as platform availability, so we'll use it where applicable but disable it otherwise
if ! find ${libdir} -name "libnetcdf*.${dlext}" -exec false '{}' +; then
    CMAKE_FLAGS+=(-DGDAL_USE_NETCDF=ON)
else
    echo "Disabling NetCDF support"
    CMAKE_FLAGS+=(-DGDAL_USE_NETCDF=OFF)
fi

# HDF5 is also a restrictive dependency as far as platform availability, so we'll use it where applicable but disable it otherwise
if ! find ${libdir} -name "libhdf5*.${dlext}" -exec false '{}' +; then
    CMAKE_FLAGS+=(-DGDAL_USE_HDF5=ON)
else
    echo "Disabling HDF5 support"
    CMAKE_FLAGS+=(-DGDAL_USE_HDF5=OFF)
fi

cmake .. ${CMAKE_FLAGS[@]}
cmake --build . -j${nproc}
cmake --build . -j${nproc} --target install
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
    Dependency("GEOS_jll"; compat="~3.11"),
    Dependency("PROJ_jll"; compat="~900.100"),
    Dependency("Zlib_jll"),
    Dependency("SQLite_jll"),
    Dependency("OpenJpeg_jll"),
    Dependency("Expat_jll"; compat="2.2.10"),
    Dependency("Zstd_jll"),
    Dependency("Libtiff_jll"; compat="4.3"),
    Dependency("libgeotiff_jll"; compat="100.700.100"),
    Dependency("LibCURL_jll"; compat="7.73"),
    Dependency("NetCDF_jll"; compat="400.902.5"),
    Dependency("HDF5_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"8")
