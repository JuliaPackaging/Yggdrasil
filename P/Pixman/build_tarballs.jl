using BinaryBuilder

# Collection of sources required to build Pixman
name = "Pixman"
version = v"0.40.0"
sources = [
    ArchiveSource("https://www.cairographics.org/releases/pixman-$(version).tar.gz",
                  "6d200dec3740d9ec4ec8d1180e25779c00bc749f94278c8b9021f5534db223fc"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pixman-*/

./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libpixman-1", :libpixman)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
