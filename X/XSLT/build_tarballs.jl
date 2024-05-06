using BinaryBuilder

name = "XSLT"
version = v"1.1.39"

# Collection of sources required to build XSLT
sources = [
    GitSource("https://gitlab.gnome.org/GNOME/libxslt.git",
              "743ab691bed98ed11ac99bbd9d903d59fb814ab8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxslt/

autoreconf -fiv
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install

# Remove heavy doc directoriy
rm -rf ${prefix}/share/doc/libxslt-*
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
    Dependency("Libgpg_error_jll"; compat="1.49.0"),
    Dependency("Libgcrypt_jll"; compat="1.8.11"),
    Dependency("Libiconv_jll"),
    Dependency("XML2_jll"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
