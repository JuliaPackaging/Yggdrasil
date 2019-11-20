# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GibbsSeaWater"
version = v"3.5.0"

# Collection of sources required to build GibbsSeaWater
# note 3.05.0-4 is too old to be cross-compiled on FreeBSD
sources = [
    "https://github.com/TEOS-10/GSW-C/archive/d392e91cb63341f543ed1609c4eff613055ab3cb.zip" =>
    "454c46ec00468aeba048fa4f3cee095f927925ab699b1d1b3a25a838cef2d22c",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/GSW-C-*
$CC $CFLAGS -fPIC -c -O3 -Wall  gsw_oceanographic_toolbox.c gsw_saar.c

if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ] || [ $target = "x86_64-apple-darwin14" ]; then
   LD=$CC
elif [ $target = "x86_64-unknown-freebsd11.1" ]; then
   LD=ld
fi

$LD $LDFLAGS -fPIC -shared -o libgswteos-10.$dlext gsw_oceanographic_toolbox.o gsw_saar.o -lm
cp libgswteos-10.$dlext $prefix
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgswteos-10", :libgswteos)
]

# Dependencies that must be installed before this package can be built
dependencies = [

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
