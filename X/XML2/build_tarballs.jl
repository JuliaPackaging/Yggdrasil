# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "XML2"
version = v"2.13.1"

# Collection of sources required to build XML2
sources = [
    ArchiveSource("https://download.gnome.org/sources/libxml2/$(version.major).$(version.minor)/libxml2-$(version).tar.xz",
                  "25239263dc37f5f55a5393eff27b35f0b7d9ea4b2a7653310598ea8299e3b741"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/libxml2-*

./autogen.sh --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --without-python \
    --disable-static \
    --with-zlib=${prefix} \
    --with-iconv=${prefix} \
    "${EXTRA_ARGS[@]}"
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
