# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "XML2"
version = v"2.9.10"

# Collection of sources required to build XML2Builder
sources = [
    ArchiveSource("https://github.com/GNOME/libxml2/archive/v$(version).tar.gz",
                  "3bdffb4d728e4dc135b3210bf2a2cebb76548b820a5617c68abb7b83654066dd"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/libxml2-*
./autogen.sh --prefix=${prefix} --host=${target} \
    --without-python \
    --disable-static \
    --with-zlib=${prefix} \
    --with-iconv=${prefix}
make -j${nproc}
make install

# Remove heavy doc directories
rm -rf ${prefix}/share/{doc/libxml2-*,gtk-doc}
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
    Dependency("Zlib_jll"),
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

