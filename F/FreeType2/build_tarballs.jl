# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "FreeType2"
version = v"2.10.1"

# Collection of sources required to build FreeType2
sources = [
    "https://download.savannah.gnu.org/releases/freetype/freetype-$(version).tar.gz" =>
    "3a60d391fd579440561bf0e7f31af2222bc610ad6ce4d9d7bd2165bca8669110",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/freetype-*/
./configure --prefix=${prefix} --host=${target} --enable-shared --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libfreetype", :libfreetype),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Bzip2_jll",
    "Zlib_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
