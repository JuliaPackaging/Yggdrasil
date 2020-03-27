# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GEOS"
version = v"3.8.1"

# Collection of sources required to build GEOS
sources = [
    "http://download.osgeo.org/geos/geos-$version.tar.bz2" =>
    "4258af4308deb9dbb5047379026b4cd9838513627cb943a44e16c40e42ae17f7",
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
export CFLAGS="-O2"
export CXXFLAGS="-O2"
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
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
