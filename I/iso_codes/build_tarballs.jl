# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "iso_codes"
version = v"4.3"

# Collection of sources required to build iso-codes
sources = [
    "https://salsa.debian.org/iso-codes-team/iso-codes/-/archive/iso-codes-$(version.major).$(version.minor)/iso-codes-iso-codes-$(version.major).$(version.minor).tar.bz2" =>
    "6b539f915d02c957c45fce8133670811f1c36a1f1535d5af3dd95dc519d3c386"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/iso-codes-*/
apk add gettext
./configure --prefix=${prefix} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
