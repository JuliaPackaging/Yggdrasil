# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "eccodes"
version = v"2.45.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://confluence.ecmwf.int/download/attachments/45757960/eccodes-$version-Source.tar.gz",
                  "6c84b39d7cc5e3b8330eeabe880f3e337f9b2ee1ebce20ea03eecd785f6c39a1"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/eccodes-*-Source
if [[ ${target} = *-mingw* ]] ; then
    chmod +x cmake/ecbuild_windows_replace_symlinks.sh
    atomic_patch -p1 /workspace/srcdir/patches/windows.patch
fi
atomic_patch -p1 /workspace/srcdir/patches/unix.patch
atomic_patch -p1 /workspace/srcdir/patches/kinds.patch
mkdir build
cd build
export CFLAGS="-I${includedir}"
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_EXAMPLES=OFF \
    -DENABLE_TESTS=OFF \
    -DENABLE_NETCDF=OFF \
    -DENABLE_PNG=ON \
    -DENABLE_FORTRAN=ON \
    -DENABLE_ECCODES_THREADS=ON \
    -DENABLE_AEC=ON $maccmakeargs \
    ..
make -j${nproc}
make install
install_license ../LICENSE
"""

# This is needed for std::bad_optional_access
sources, script = require_macos_sdk("11.1", sources, script; deployment_target="10.14")

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# 32 bit platforms are not supported by eccodes
filter!(p -> nbits(p) == 64, platforms)

# dependencies are not available on RISC-V
filter!(p -> arch(p) != "riscv64", platforms)

# dependencies are not available on 64bit ARM FreeBSD
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)
filter!(p -> libgfortran_version(p) != v"3", platforms) # Avoid too old GCC
# The products that we will ensure are always built
products = [
    LibraryProduct("libeccodes", :eccodes),
    LibraryProduct("libeccodes_f90", :libeccodes_f90),
    ExecutableProduct("bufr_compare", :bufr_compare),
    ExecutableProduct("bufr_copy", :bufr_copy),
    ExecutableProduct("bufr_count", :bufr_count),
    ExecutableProduct("bufr_dump", :bufr_dump),
    ExecutableProduct("bufr_get", :bufr_get),
    ExecutableProduct("bufr_index_build", :bufr_index_build),
    ExecutableProduct("bufr_ls", :bufr_ls),
    ExecutableProduct("bufr_set", :bufr_set),
    ExecutableProduct("codes_bufr_filter", :codes_bufr_filter),
    ExecutableProduct("codes_count", :codes_count),
    ExecutableProduct("codes_export_resource", :codes_export_resource),
    ExecutableProduct("codes_info", :codes_info),
    ExecutableProduct("codes_parser", :codes_parser),
    ExecutableProduct("codes_split_file", :codes_split_file),
    ExecutableProduct("grib2ppm", :grib2ppm),
    ExecutableProduct("grib_compare", :grib_compare),
    ExecutableProduct("grib_copy", :grib_copy),
    ExecutableProduct("grib_count", :grib_count),
    ExecutableProduct("grib_dump", :grib_dump),
    ExecutableProduct("grib_filter", :grib_filter),
    ExecutableProduct("grib_get_data", :grib_get_data),
    ExecutableProduct("grib_get", :grib_get),
    ExecutableProduct("grib_histogram", :grib_histogram),
    ExecutableProduct("grib_index_build", :grib_index_build),
    ExecutableProduct("grib_ls", :grib_ls),
    ExecutableProduct("grib_set", :grib_set),
    ExecutableProduct("gts_compare", :gts_compare),
    ExecutableProduct("gts_copy", :gts_copy),
    ExecutableProduct("gts_count", :gts_count),
    ExecutableProduct("gts_dump", :gts_dump),
    ExecutableProduct("gts_filter", :gts_filter),
    ExecutableProduct("gts_get", :gts_get),
    ExecutableProduct("gts_ls", :gts_ls),
    FileProduct("share/eccodes/definitions", :eccodes_definitions),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("libpng_jll"; compat="~1.6.43"),
    Dependency("OpenJpeg_jll", compat="~2.5.2"),
    Dependency("libaec_jll", compat="~1.1.5"),
]

init_block = raw"""
ENV["ECCODES_DEFINITION_PATH"] = eccodes_definitions
"""

# Build the tarballs, and possibly a `build.jl` as well. GCC 8 because we need C++17
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8", clang_use_lld=false, julia_compat="1.6", init_block)
