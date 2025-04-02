# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "iso_codes"
version = v"4.17.0"

# Collection of sources required to build iso-codes
sources = [
    ArchiveSource("https://salsa.debian.org/iso-codes-team/iso-codes/-/archive/v$(version)/iso-codes-v$(version).tar.bz2",
                  "6d178ef4cea44e55f02eb546b29dcf68d88e9f7a68e0dd7913f5465dbaf8fc14"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/iso-codes-*
apk update
apk add gettext
./configure --prefix=${prefix}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = Product[
    FileProduct("share/iso-codes", :iso_codes_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
