# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libcap_Ng"
version = v"0.7.10"

# Collection of sources required to build libcap-ng
sources = [
    "http://people.redhat.com/sgrubb/libcap-ng/libcap-ng-$(version).tar.gz" =>
    "a84ca7b4e0444283ed269b7a29f5b6187f647c82e2b876636b49b9a744f0ffbf",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libcap-ng-*/
./configure --prefix=${prefix} --host=${target} \
    --enable-static=no \
    -with-python=no \
    CFLAGS="${CFLAGS} -pthread"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = [p for p in supported_platforms() if p isa Linux]

# The products that we will ensure are always built
products = [
    LibraryProduct("libcap-ng", :libcap_ng),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
