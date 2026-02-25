# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "GDAL"
upstream_version = v"3.12.2"
# The version offset is used for two purposes:
# - If we need to release multiple jll packages for the same GDAL
#   library (usually for weird packaging reasons) then we increase the
#   offset because we usually cannot release the same version twice.
# - Minor versions of GDAL are usually binary incompatible because
#   they increase the shared library soname. To encode this, we
#   increase the major version number of the version offset.
version_offset = v"4.0.0"
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to build GDAL
sources = [
    GitSource("https://github.com/OSGeo/gdal.git", "ad23f3eddc646081f719852b349f68654a1d06d3"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gdal

atomic_patch -p1 ../patches/bsd-environ-undefined-fix.patch
# Some of our Linux build environments are too old to define `O_TMPFILE`; define it manually
atomic_patch -p1 ../patches/tmpfile.patch

if [[ "${target}" == *-freebsd* ]]; then
    # Our FreeBSD libc has `environ` as undefined symbol, so the linker will
    # complain if this symbol is used in the built library, even if this won't
    # be a problem at runtime. The flag `-undefined` allows having undefined symbols.
    # The flag `-lexecinfo` fixes "undefined reference to `backtrace'".
    export LDFLAGS="-lexecinfo -undefined"
fi

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
    -DGDAL_ENABLE_DRIVER_HDF4=ON
    -DGDAL_USE_BLOSC=ON
    -DGDAL_USE_CURL=ON
    -DGDAL_USE_EXPAT=ON
    -DGDAL_USE_HDF4=ON
    -DGDAL_USE_GEOS=ON
    -DGDAL_USE_GEOTIFF=ON
    -DGDAL_USE_HDF4=ON
    -DGDAL_USE_HDF5=ON
    -DGDAL_USE_LERC=ON
    -DGDAL_USE_LIBLZMA=ON
    -DGDAL_USE_LIBXML2=ON
    -DGDAL_USE_LZ4=ON
    -DGDAL_USE_NETCDF=ON
    -DGDAL_USE_OPENJPEG=ON
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

# Use Arrow only if available
if [ -e "${libdir}/libarrow.${dlext}" ]; then
    CMAKE_FLAGS+=(
        -DGDAL_USE_ARROW=ON
        -DGDAL_USE_PARQUET=ON
    )
fi

# Disable gif on Windows
if [[ "${target}" == *mingw* ]]; then
    CMAKE_FLAGS+=(-DGDAL_USE_GIF=OFF)   # Would break GDAL on Windows as of Giflib_jll v5.2.2 (#8781)
fi

cmake ${CMAKE_FLAGS[@]}
cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE.TXT
"""

# Work around the issue
# /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/local/include/arrow/type.h:1745:36: error: 'get<arrow::FieldPath, arrow::FieldPath, std::basic_string<char>, std::vector<arrow::FieldRef>>' is unavailable: introduced in macOS 10.14
#     if (IsFieldPath()) return std::get<FieldPath>(impl_).indices().size() > 1;
#                                    ^
# /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/include/c++/v1/variant:1394:22: note: 'get<arrow::FieldPath, arrow::FieldPath, std::basic_string<char>, std::vector<arrow::FieldRef>>' has been explicitly marked unavailable here
# ...and install a newer SDK
sources, script = require_macos_sdk("10.15", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libgdal", :libgdal),

    # Using a `_path` suffix here would be very confusing because BinaryBuilder already adds a `_path` suffix.
    ExecutableProduct("gdal", :gdal_exe),
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

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="OpenMPI_jll", version="4.1.8"); platforms=filter(p -> nbits(p)==32, platforms)),
    Dependency("Arrow_jll"; compat="19.0.0"),
    Dependency("Blosc_jll"; compat="1.21.7"),
    Dependency("Expat_jll"; compat="2.6.5"),
    Dependency("GEOS_jll"; compat="3.13.1"),
    Dependency("HDF4_jll"; compat="4.3.1"),
    Dependency("HDF5_jll"; compat="~1.14.6"),
    Dependency("LERC_jll"; compat="4.0.1"),
    Dependency("LibCURL_jll"; compat="7.73,8"),
    Dependency("LibPQ_jll"; compat="16.8"),
    Dependency("Libtiff_jll"; compat="4.7.1"),
    Dependency("Lz4_jll"; compat="1.10.1"),
    Dependency("NetCDF_jll"; compat="401.900.300"),
    Dependency("OpenJpeg_jll"; compat="2.5.4"),
    Dependency("PCRE2_jll"; compat="10.42.0"),
    Dependency("PROJ_jll"; compat="902.500.100"),
    Dependency("Qhull_jll"; compat="10008.0.1004"),
    Dependency("SQLite_jll"; compat="3.48.0"),
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency("XML2_jll"; compat="~2.13.6"),
    Dependency("XZ_jll"; compat="5.6.4"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("Zstd_jll"; compat="1.5.7"),
    Dependency("libgeotiff_jll"; compat="100.702.400"),
    Dependency("libpng_jll"; compat="1.6.47"),
    Dependency("libwebp_jll"; compat="1.5.0"),
    Dependency("muparser_jll"; compat="2.3.5"),
    # Disable exprtk on Windows, it exports too many symbols (21086, with at most 65535 allowed)
    BuildDependency("exprtk_jll", platforms=filter(!Sys.iswindows, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
#
# NOTE: Building with GCC 12 fails on x86_64. GCC 12 enables compiler
# support for float16, but would (apparently? hopefully?) use the
# respective soft-fp emulation routines. These are only available in
# `libcc` of GCC 12 and later, and thus this file isn't guaranteed to
# be available. Therefore we need to disable compiler support for
# float16 (on x86_64), e.g. by using GCC 11 or earlier.
#
# GDAL will then still support float16, but only via emulation, i.e.
# converting from/to float32.
#
# We could enable compiler support for float16 if we can guarantee
# that the CPU supports respective hardware instructions so that we
# don't need soft-fp from libgcc.
#
# NOTE: Require at least Julia 1.9 because we use a PCRE2_jll that is
# not available on earlier versions.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9", preferred_gcc_version=v"11")
