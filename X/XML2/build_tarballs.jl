# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "XML2"
version = v"2.9.9"

# Collection of sources required to build XML2Builder
sources = [
    "https://github.com/GNOME/libxml2/archive/v$(version).tar.gz" =>
    "d673f0284cec867ee00872a8152e0c3c09852f17fd9aa93f07579a37534f0bfe",
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/libxml2-*
./autogen.sh --prefix=${prefix} --host=${target} \
    --without-python \
    --with-zlib=${prefix} \
    --with-iconv=${prefix}
make -j${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libxml2", :libxml2),
    ExecutableProduct("xmlcatalog", :xmlcatalog),
    ExecutableProduct("xmllint", :xmllint),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Zlib_jll",
    "Libiconv_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
