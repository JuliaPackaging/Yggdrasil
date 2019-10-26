# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libmodplug"
version = v"0.8.9"

# Collection of sources required to build libmodplug
sources = [
    "https://downloads.sourceforge.net/modplug-xmms/libmodplug-$(version).0.tar.gz" =>
    "457ca5a6c179656d66c01505c0d95fafaead4329b9dbaa0f997d00a3508ad9de",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libmodplug-*/
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmodplug", :libmodplug),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
