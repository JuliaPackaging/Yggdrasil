using BinaryBuilder

name = "XSLT"
version = v"1.1.42"

# Collection of sources required to build XSLT
sources = [
    ArchiveSource("https://download.gnome.org/sources/libxslt/$(version.major).$(version.minor)/libxslt-$(version).tar.xz",
                  "85ca62cac0d41fc77d3f6033da9df6fd73d20ea2fc18b0a3609ffb4110e1baeb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxslt-*

# XSLT wants Python 2.7... XML2_jll disables Python, so let's do that here as well.
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static --with-python=no
make -j${nproc}
make install

# Remove heavy doc directoriy
rm -rf ${prefix}/share/doc/libxslt-*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libxslt", :libxslt),
    LibraryProduct("libexslt", :libexslt),
]

# Dependencies that must be installed before this package can be built
# - Build against XML2_jll v2.12.7 as it bundles the string-handling trio library,
#   and the i686-w64-mingw32 build implicitly needs it.
#   Removed in v2.13.0:
#   https://gitlab.gnome.org/GNOME/libxml2/-/blob/fe1ee0f25f43e33a9981fd6fe7b0483a8c8b5e8d/NEWS#L173
dependencies = [
    Dependency("Libgpg_error_jll"; compat="1.50"),
    Dependency("Libgcrypt_jll"),
    Dependency("Libiconv_jll"),
    Dependency("XML2_jll", v"2.12.7"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# XML2_jll builds with GCC 8 and we need to do the same to avoid linker errors
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8", )
