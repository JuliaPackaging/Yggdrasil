# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "GEOS"
version = v"3.14.1"

# Collection of sources required to build GEOS
sources = [
    ArchiveSource("http://download.osgeo.org/geos/geos-$version.tar.bz2",
                  "3c20919cda9a505db07b5216baa980bacdaa0702da715b43f176fb07eff7e716"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/geos-*/

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${MACHTYPE})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DBUILD_TESTING=OFF)
CMAKE_FLAGS+=(-S.) # source

# arm complains about duplicate symbols unless we disable inlining
if [[ ${target} == arm* ]]; then
    CMAKE_FLAGS+=(-DDISABLE_GEOS_INLINE=true)
fi

cmake ${CMAKE_FLAGS[@]}
make -j${nproc}
make install
"""

# We need a newer C++ library
sources, script = require_macos_sdk("11.3", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libgeos_c", :libgeos),
    LibraryProduct(["libgeos", "libgeos-$(version.major)-$(version.minor)"], :libgeos_cpp),
    ExecutableProduct("geosop", :geosop),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 7 for newer C++ features
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")
