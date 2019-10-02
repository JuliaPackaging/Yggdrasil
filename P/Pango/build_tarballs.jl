# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Pango"
version = v"1.42.4"

# Collection of sources required to build Pango
sources = [
    "http://ftp.gnome.org/pub/GNOME/sources/pango/$(version.major).$(version.minor)/pango-$(version).tar.xz" =>
    "1d2b74cd63e8bd41961f2f8d952355aa0f9be6002b52c8aa7699d9f5da597c9d"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pango-*/

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la

# Be able to find libffi on ppc64le
if [[ ${target} == powerpc64le* ]]; then
    export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${prefix}/lib64"
fi

./configure --prefix=$prefix --host=$target \
    --disable-introspection \
    --disable-gtk-doc-html

# The generated Makefile tries to build some examples in the "tests" directory,
# but this would fail for some unknown reasons.  Let's skip it.
sed -i 's/^\(SUBDIRS = .*\) tests/\1/' Makefile
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libpango", "libpango-1", "libpango-1.0"], :libpango),
    LibraryProduct(["libpangocairo", "libpangocairo-1", "libpangocairo-1.0"], :libpangocairo),
    LibraryProduct(["libpangoft2", "libpangoft2-1", "libpangoft2-1.0"], :libpangoft),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "FriBidi_jll",
    "FreeType2_jll",
    "Glib_jll",
    "Fontconfig_jll",
    "HarfBuzz_jll",
    "Cairo_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
