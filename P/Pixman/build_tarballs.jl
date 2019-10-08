using BinaryBuilder

# Collection of sources required to build Pixman
name = "Pixman"
version = v"0.38.4"
sources = [
    "https://www.cairographics.org/releases/pixman-$(version).tar.gz" =>
    "da66d6fd6e40aee70f7bd02e4f8f76fc3f006ec879d346bae6a723025cfbdde7",
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
    LibraryProduct("libpixman", :libpixman)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
product_hashes = build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
