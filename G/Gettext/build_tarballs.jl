using BinaryBuilder

# Collection of sources required to build Gettext
name = "Gettext"
version = v"0.20.1"
sources = [
    ArchiveSource("https://ftp.gnu.org/pub/gnu/gettext/gettext-$(version).tar.xz",
                  "53f02fbbec9e798b0faaf7c73272f83608e835c6288dd58be6c9bb54624a3800"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gettext-*/
export CFLAGS="-O2"
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgettextlib", "libgettextlib-0-20"], :libgettext)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libiconv_jll"),
    Dependency("XML2_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
