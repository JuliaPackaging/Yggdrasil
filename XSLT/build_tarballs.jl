using BinaryBuilder

name = "XSLT"
version = v"1.1.32"

# Collection of sources required to build Ogg
sources = [
    "https://github.com/GNOME/libxslt/archive/v$(version).tar.gz" =>
    "2d9123cd4f142905fe2d281a5318ef74a9217bd17501fbc4213460fbf747d01a",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxslt-*/

./autogen.sh --prefix=${prefix} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable FreeBSD for now (relocation R_X86_64_32S error)
platforms = [p for p in platforms if !(typeof(p) <: FreeBSD)]

# The products that we will ensure are always built
products = prefix -> [
    LibraryProduct(prefix, "libxslt", :libxslt),
    LibraryProduct(prefix, "libexslt", :libexslt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.3/build_Zlib.v1.2.11.jl",
    "https://github.com/bicycle1885/XML2Builder/releases/download/v1.0.1/build_XML2Builder.v2.9.7.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
