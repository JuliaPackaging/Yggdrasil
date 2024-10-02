using BinaryBuilder

name = "XSLT"
version = v"1.1.41"

# Collection of sources required to build XSLT
sources = [
    ArchiveSource("https://download.gnome.org/sources/libxslt/$(version.major).$(version.minor)/libxslt-$(version).tar.xz",
                  "3ad392af91115b7740f7b50d228cc1c5fc13afc1da7f16cb0213917a37f71bda"),
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
dependencies = [
    Dependency("Libgpg_error_jll", v"1.42.0"; compat="1.42.0"),
    Dependency("Libgcrypt_jll"),
    Dependency("Libiconv_jll"),
    Dependency("XML2_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# XML2_jll builds with GCC 8 and we need to do the same to avoid linker errors
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8", )
