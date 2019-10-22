# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GEOS"
version = v"3.8.0"

# Collection of sources required to build GEOS
sources = [
    "http://download.osgeo.org/geos/geos-$version.tar.bz2" =>
    "99114c3dc95df31757f44d2afde73e61b9f742f0b683fd1894cbbee05dda62d5",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/geos-*/

# ppc64le doesn't think it can create shared libraries, because `./configure`
# passes in `-m elf64ppc` when it should be passing `-m elf64lppc`, because this
# is ppc64le not ppc64.  Teach it the difference.
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/configure_ppc64le.patch"

# arm complains about duplicate symbols unless we disable inlining
EXTRA_CONFIGURE_FLAGS=()
if [[ ${target} == arm* ]]; then
    EXTRA_CONFIGURE_FLAGS+=(--disable-inline)
fi
./configure --prefix=$prefix --build=${MACHTYPE} --host=$target --enable-shared ${EXTRA_CONFIGURE_FLAGS[@]}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgeos_c", :libgeos),
    LibraryProduct(["libgeos", "libgeos-3-8"], :libgeos_cpp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
