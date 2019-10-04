using BinaryBuilder

name = "XSLT"
version = v"1.1.33"

# Collection of sources required to build XSLT
sources = [
    "ftp://xmlsoft.org/libxslt/libxslt-$(version).tar.gz" =>
    "8e36605144409df979cab43d835002f63988f3dc94d5d3537c12796db90e38c8",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxslt-*/

./configure --prefix=${prefix} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libxslt", :libxslt),
    LibraryProduct("libexslt", :libexslt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Libgcrypt_jll",
    "XML2_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
