using BinaryBuilder

# Collection of sources required to build libserialport
name = "libserialport"
version = v"0.1.1"
sources = [
    "https://sigrok.org/gitweb/?p=libserialport.git;a=snapshot;h=HEAD;sf=zip" =>
    "4e30b81d51bb7c6bfa0c64beaba79616d18092f2f416de5061b0bf4d68f39c6d",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libserialport-*/

./autogen.sh
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
    LibraryProduct("libserialport", :libnettle)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
