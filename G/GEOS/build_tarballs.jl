# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GEOS"
version = v"3.9.0"

# Collection of sources required to build GEOS
sources = [
    ArchiveSource("http://download.osgeo.org/geos/geos-$version.tar.bz2",
                  "bd8082cf12f45f27630193c78bdb5a3cba847b81e72b20268356c2a4fc065269")
]


# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/geos-*/

# arm complains about duplicate symbols unless we disable inlining
EXTRA_CONFIGURE_FLAGS=()
if [[ ${target} == arm* ]]; then
    EXTRA_CONFIGURE_FLAGS+=(--disable-inline)
fi
export CFLAGS="-O2"
export CXXFLAGS="-O2"
autoreconf -vi
./configure --prefix=$prefix --build=${MACHTYPE} --host=$target --enable-shared --disable-static ${EXTRA_CONFIGURE_FLAGS[@]}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libgeos_c", :libgeos),
    LibraryProduct(["libgeos", "libgeos-$(version.major)-$(version.minor)"], :libgeos_cpp)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
