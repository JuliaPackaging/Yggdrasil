# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "XML2"
version = v"2.12.0"

# Collection of sources required to build XML2
sources = [
    ArchiveSource("https://download.gnome.org/sources/libxml2/$(version.major).$(version.minor)/libxml2-$(version).tar.xz",
                  "431521c8e19ca396af4fa97743b5a6bfcccddbba90e16426a15e5374cd64fe0d"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/libxml2-*

# Remove patches for next version.
atomic_patch -p1 ../patches/0001-fix-pthread-weak-references-in-globals.c.patch
atomic_patch -p1 ../patches/0002-fix-more-pthread-weak-references-in-globals.c.patch

./autogen.sh --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --without-python \
    --disable-static \
    --with-zlib=${prefix} \
    --with-iconv=${prefix}
make -j${nproc}
make install

# Remove heavy doc directories
rm -r ${prefix}/share/{doc/libxml2,man}
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

# XML2 requires full C11 support (so GCC >= 5), but GCC v5-7 crases with an ICE
# on Windows, so we need GCC 8 for that platform.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8", julia_compat="1.6")
