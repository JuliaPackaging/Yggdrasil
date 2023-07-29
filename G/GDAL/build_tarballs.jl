# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GDAL"
upstream_version = v"3.6.2"
version_offset = v"1.0.0"
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to build GDAL
sources = [
    ArchiveSource("https://github.com/OSGeo/gdal/releases/download/v$upstream_version/gdal-$upstream_version.tar.gz",
        "cd5bf004af85b88414676b0d5694d3192414e556961ee3d47164f3298078a818"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
        "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gdal-*/
install_license LICENSE.TXT

mkdir build
cd build

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
-DGDAL_USE_ZSTD=ON
-DGDAL_USE_POSTGRESQL=ON
-DPostgreSQL_INCLUDE_DIR=${includedir}
-DPostgreSQL_LIBRARY=${libdir}/libpq.${dlext}
-DGDAL_USE_ARROW=ON
-DGDAL_USE_PARQUET=ON)

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

hdf5_platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
    Platform("aarch64", "macos"),
]
hdf5_platforms = expand_cxxstring_abis(hdf5_platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GEOS_jll"; compat="~3.11"),
    Dependency("PROJ_jll"; compat="~900.100"),
    Dependency("Zlib_jll"),
    Dependency("SQLite_jll"),
    Dependency("LibPQ_jll"),
    Dependency("OpenJpeg_jll"),
    Dependency("Expat_jll"; compat="2.2.10"),
    Dependency("Zstd_jll"),
    Dependency("Libtiff_jll"; compat="4.3"),
    Dependency("libgeotiff_jll"; compat="100.700.100"),
    Dependency("LibCURL_jll"; compat="7.73,8"),
    Dependency("NetCDF_jll"; compat="400.902.5", platforms=hdf5_platforms),
    # Updating to a newer HDF5 version is likely possible without problems but requires rebuilding this package
    Dependency("HDF5_jll"; compat="~1.12", platforms=hdf5_platforms),
    Dependency("Arrow_jll"; compat="10"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
