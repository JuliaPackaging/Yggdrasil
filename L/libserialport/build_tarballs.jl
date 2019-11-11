using BinaryBuilder

# Collection of sources required to build libserialport
name = "libserialport"
version = v"0.1.1"
sources = [
    "http://sigrok.org/download/source/libserialport/libserialport-$(version).tar.gz" =>
    "4a2af9d9c3ff488e92fb75b4ba38b35bcf9b8a66df04773eba2a7bbf1fa7529d",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libserialport-*/

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
    LibraryProduct("libserialport", :libserialport)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
