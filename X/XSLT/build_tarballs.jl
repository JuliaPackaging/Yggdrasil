using BinaryBuilder

name = "XSLT"
version = v"1.1.43"

# Collection of sources required to build XSLT
sources = [
    ArchiveSource("https://download.gnome.org/sources/libxslt/$(version.major).$(version.minor)/libxslt-$(version).tar.xz",
                  "5a3d6b383ca5afc235b171118e90f5ff6aa27e9fea3303065231a6d403f0183a"),
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
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libxslt", :libxslt),
    LibraryProduct("libexslt", :libexslt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libgpg_error_jll"; compat="1.51.1"),
    Dependency("Libgcrypt_jll"; compat="1.11.1"),
    Dependency("Libiconv_jll"; compat="1.18"),
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency("XML2_jll"; compat="~2.13.6"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# XML2_jll builds with GCC 8 and we need to do the same to avoid linker errors
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"11")
