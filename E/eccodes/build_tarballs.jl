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
    ExecutableProduct("grib_set", :grib_set),
    FileProduct("share/eccodes/definitions", :eccodes_definitions)
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
