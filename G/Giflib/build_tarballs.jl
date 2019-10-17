# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Giflib"
version = v"5.1.4"

# Collection of sources required to build Giflib
sources = [
    "https://downloads.sourceforge.net/project/giflib/giflib-$(version).tar.bz2" =>
    "df27ec3ff24671f80b29e6ab1c4971059c14ac3db95406884fc26574631ba8d5",

    # Apply security patch
    "https://deb.debian.org/debian/pool/main/g/giflib/giflib_5.1.4-3.debian.tar.xz" =>
    "767ea03c1948fa203626107ead3d8b08687a3478d6fbe4690986d545fb1d60bf",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/giflib-*/
atomic_patch -p1 ../debian/patches/CVE-2016-3977.patch

# We need to massage configure script to convince it to build the shared library
# for PowerPC.
if [[ "${target}" == powerpc64le-* ]]; then
    autoreconf -vi
fi

update_configure_scripts
./configure --prefix=${prefix} --host=${target}
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgif", :libgif),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
