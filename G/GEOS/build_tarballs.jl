# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GEOS"
version = v"3.13.0"
ygg_version = v"3.13.1" # bump ygg version to pick up new platforms

# Collection of sources required to build GEOS
sources = [
    ArchiveSource("http://download.osgeo.org/geos/geos-$version.tar.bz2",
                  "47ec83ff334d672b9e4426695f15da6e6368244214971fabf386ff8ef6df39e4" )
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/geos-*/

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${MACHTYPE})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-S.) # source

# arm complains about duplicate symbols unless we disable inlining
if [[ ${target} == arm* ]]; then
    CMAKE_FLAGS+=(-DDISABLE_GEOS_INLINE=true)
fi

cmake ${CMAKE_FLAGS[@]}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libgeos_c", :libgeos),
    LibraryProduct(["libgeos", "libgeos-$(version.major)-$(version.minor)"], :libgeos_cpp),
    ExecutableProduct("geosop", :geosop),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")
