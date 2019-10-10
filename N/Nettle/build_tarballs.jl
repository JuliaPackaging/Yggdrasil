using BinaryBuilder

# Collection of sources required to build Nettle
name = "Nettle"
version = v"3.4.1"
sources = [
    "https://ftp.gnu.org/gnu/nettle/nettle-$(version).tar.gz" =>
    "f941cf1535cd5d1819be5ccae5babef01f6db611f9b5a777bae9c7604b8a92ad",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nettle-*/

# Force c99 mode
export CFLAGS="${CFLAGS} -std=c99"

update_configure_scripts
./configure --prefix=$prefix --host=$target --with-include-path=$prefix/include
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable FreeBSD for now, because hogweed needs alloca()?
platforms = [p for p in platforms if !(typeof(p) <: FreeBSD)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libnettle", :libnettle),
    LibraryProduct("libhogweed", :libhogweed),
    ExecutableProduct("nettle-hash", :nettle_hash)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "GMP_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
