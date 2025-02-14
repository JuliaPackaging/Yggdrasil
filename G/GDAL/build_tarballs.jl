# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GDAL"
upstream_version = v"3.10.2"
# The version offset is used for two purposes:
# - If we need to release multiple jll packages for the same GDAL
#   library (usually for weird packaging reasons) then we increase the
#   offset because we usually cannot release the same version twice.
# - Minor versions of GDAL are usually binary incompatible because
#   they increase the shared library soname. To encode this, we
#   increase the major version number of the version offset.
version_offset = v"2.0.0"
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to build GDAL
sources = [
    GitSource("https://github.com/OSGeo/gdal.git",
        "e31053b64d9db2e0dc6f8eec0982908a2087eedf"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
        "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gdal

atomic_patch -p1 ../patches/bsd-environ-undefined-fix.patch

if [[ "${target}" == *-freebsd* ]]; then
    # Our FreeBSD libc has `environ` as undefined symbol, so the linker will
    # complain if this symbol is used in the built library, even if this won't
    # be a problem at runtime. The flag `-undefined` allows having undefined symbols.
    # The flag `-lexecinfo` fixes "undefined reference to `backtrace'".
    export LDFLAGS="-lexecinfo -undefined"
fi

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Work around the issue
    # /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/local/include/arrow/type.h:1745:36: error: 'get<arrow::FieldPath, arrow::FieldPath, std::basic_string<char>, std::vector<arrow::FieldRef>>' is unavailable: introduced in macOS 10.14
    #     if (IsFieldPath()) return std::get<FieldPath>(impl_).indices().size() > 1;
    #                                    ^
    # /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/include/c++/v1/variant:1394:22: note: 'get<arrow::FieldPath, arrow::FieldPath, std::basic_string<char>, std::vector<arrow::FieldRef>>' has been explicitly marked unavailable here
    export MACOSX_DEPLOYMENT_TARGET=10.15
    # ...and install a newer SDK
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi

# We cannot enable HDF4. Our HDF4_jll package provides a file `netcdf.h` that conflicts with NetCDF_jll.
# -DGDAL_ENABLE_DRIVER_HDF4=ON
# -DGDAL_USE_HDF4=ON

CMAKE_FLAGS=(
    -B build
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_FIND_ROOT_PATH=${prefix}
    -DCMAKE_PREFIX_PATH=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DBUILD_CSHARP_BINDINGS=OFF
    -DBUILD_JAVA_BINDINGS=OFF
    -DBUILD_PYTHON_BINDINGS=OFF
    -DGDAL_USE_ARROW=ON
    -DGDAL_USE_BLOSC=ON
    -DGDAL_USE_CURL=ON
    -DGDAL_USE_EXPAT=ON
    -DGDAL_USE_GEOS=ON
    -DGDAL_USE_GEOTIFF=ON
    # TODO: Disable gif only on Windows
    -DGDAL_USE_GIF=OFF   # Would break GDAL on Windows as of Giflib_jll v5.2.2 (#8781)
    -DGDAL_USE_LERC=ON
    -DGDAL_USE_LIBLZMA=ON
    -DGDAL_USE_LIBXML2=ON
    -DGDAL_USE_LZ4=ON
    -DGDAL_USE_OPENJPEG=ON
    -DGDAL_USE_PARQUET=ON
    -DGDAL_USE_PNG=ON
    -DGDAL_USE_POSTGRESQL=ON
    -DGDAL_USE_QHULL=ON
    -DGDAL_USE_SQLITE3=ON
    -DGDAL_USE_TIFF=ON
    -DGDAL_USE_WEBP=ON
    -DGDAL_USE_ZLIB=ON
    -DGDAL_USE_ZSTD=ON
    -DGIF_LIBRARY=${libdir}/libgif.${dlext}
    -DPCRE2-8_LIBRARY=${libdir}/libpcre2-8.${dlext}
    -DPCRE2_INCLUDE_DIR=${includedir}
    -DPostgreSQL_INCLUDE_DIR=${includedir}
    -DPostgreSQL_LIBRARY=${libdir}/libpq.${dlext}
)

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

cmake ${CMAKE_FLAGS[@]}
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libgdal", :libgdal),

    # Using a `_path` suffix here is very confusing because BinaryBuilder already adds a `_path` suffix.
    ExecutableProduct("gdal_contour", :gdal_contour_exe),
    ExecutableProduct("gdal_create", :gdal_create_exe),
    ExecutableProduct("gdal_footprint", :gdal_footprint_exe),
    ExecutableProduct("gdal_grid", :gdal_grid_exe),
    ExecutableProduct("gdal_rasterize", :gdal_rasterize_exe),
    ExecutableProduct("gdal_translate", :gdal_translate_exe),
    ExecutableProduct("gdal_viewshed", :gdal_viewshed_exe),
    ExecutableProduct("gdaladdo", :gdaladdo_exe),
    ExecutableProduct("gdalbuildvrt", :gdalbuildvrt_exe),
    ExecutableProduct("gdaldem", :gdaldem_exe),
    ExecutableProduct("gdalenhance", :gdalenhance_exe),
    ExecutableProduct("gdalinfo", :gdalinfo_exe),
    ExecutableProduct("gdallocationinfo", :gdallocationinfo_exe),
    ExecutableProduct("gdalmanage", :gdalmanage_exe),
    ExecutableProduct("gdalmdiminfo", :gdalmdiminfo_exe),
    ExecutableProduct("gdalmdimtranslate", :gdalmdimtranslate_exe),
    ExecutableProduct("gdalsrsinfo", :gdalsrsinfo_exe),
    ExecutableProduct("gdaltindex", :gdaltindex_exe),
    ExecutableProduct("gdaltransform", :gdaltransform_exe),
    ExecutableProduct("gdalwarp", :gdalwarp_exe),
    ExecutableProduct("gnmanalyse", :gnmanalyse_exe),
    ExecutableProduct("gnmmanage", :gnmmanage_exe),
    ExecutableProduct("nearblack", :nearblack_exe),
    ExecutableProduct("ogr2ogr", :ogr2ogr_exe),
    ExecutableProduct("ogrinfo", :ogrinfo_exe),
    ExecutableProduct("ogrlineref", :ogrlineref_exe),
    ExecutableProduct("ogrtindex", :ogrtindex_exe),
    ExecutableProduct("sozip", :sozip_exe),

    # For backward compatibility keep the old names (which have the confusing `_path` suffix)
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

hdf5_platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
    Platform("armv6l", "linux"),
    Platform("armv7l", "linux"),
    Platform("i686", "linux"),
    Platform("powerpc64le", "linux"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
]
hdf5_platforms = expand_cxxstring_abis(hdf5_platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="OpenMPI_jll", version=v"4.1.6"); platforms=filter(p -> nbits(p)==32, platforms)),
    Dependency("Arrow_jll"; compat="18.1.0"),
    Dependency("Blosc_jll"; compat="1.21.1"),
    Dependency("Expat_jll"; compat="2.2.10"),
    Dependency("GEOS_jll"; compat="3.11.2"),
    # Dependency("HDF4_jll"; compat="4.3.0"),
    Dependency("HDF5_jll"; compat="~1.14.3", platforms=hdf5_platforms),
    Dependency("LERC_jll"; compat="4"),
    Dependency("LibCURL_jll"; compat="7.73,8"),
    Dependency("LibPQ_jll"; compat="16"),
    Dependency("Libtiff_jll"; compat="4.7"),
    Dependency("Lz4_jll"; compat="1.9.3"),
    Dependency("NetCDF_jll"; compat="400.902.210", platforms=hdf5_platforms),
    Dependency("OpenJpeg_jll"; compat="2.5"),
    Dependency("PCRE2_jll"; compat="10.35.0"),
    Dependency("PROJ_jll"; compat="902.500"),
    Dependency("Qhull_jll"; compat="8.0.999"),
    Dependency("SQLite_jll"; compat="3.45"),
    Dependency("XML2_jll"; compat="2.9.11"),
    Dependency("XZ_jll"; compat="5.2.5"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("Zstd_jll"; compat="1.5.6"),
    Dependency("libgeotiff_jll"; compat="100.702.300"),
    Dependency("libpng_jll"; compat="1.6.38"),
    Dependency("libwebp_jll"; compat="1.2.4"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
