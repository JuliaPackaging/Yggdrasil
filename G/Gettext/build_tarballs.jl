using BinaryBuilder

# Collection of sources required to build Gettext
name = "Gettext"
version = v"0.20.1"
sources = [
    "https://ftp.gnu.org/pub/gnu/gettext/gettext-$(version).tar.xz" =>
    "53f02fbbec9e798b0faaf7c73272f83608e835c6288dd58be6c9bb54624a3800",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gettext-*/

./configure --prefix=$prefix --host=$target CFLAGS="-O2"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgettext", :libgettext)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Libiconv_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

