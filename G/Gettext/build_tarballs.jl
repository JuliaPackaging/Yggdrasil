using BinaryBuilder

# Collection of sources required to build Gettext
name = "Gettext"
version = v"0.20.2"
sources = [
    ArchiveSource("https://ftp.gnu.org/pub/gnu/gettext/gettext-$(version).tar.xz",
                  "b22b818e644c37f6e3d1643a1943c32c3a9bff726d601e53047d2682019ceaba"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gettext-*/

export CFLAGS="-O2"
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-static \
    --enable-relocatable \
    --with-libiconv-prefix=${prefix} \
    am_cv_lib_iconv=yes \
    am_cv_func_iconv=yes
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgettextlib", "libgettextlib-$(version.major)-$(version.minor)"], :libgettext)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Libiconv_jll"),
    Dependency("XML2_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
