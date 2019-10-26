# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "mpg123"
version = v"1.25.12"

# Collection of sources required to build mpg123
sources = [
    "https://downloads.sourceforge.net/sourceforge/mpg123/mpg123-$(version).tar.bz2" =>
    "1ffec7c9683dfb86ea9040d6a53d6ea819ecdda215df347f79def08f1fe731d1",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mpg123-*/
./configure --prefix=$prefix --host=$target --enable-int-quality
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmpg123", :libmpg123),
    LibraryProduct("libout123", :libout123),
    ExecutableProduct("mpg123", :mpg123),
    ExecutableProduct("mpg123-id3dump", :mpg123_id3dump),
    ExecutableProduct("mpg123-strip", :mpg123_strip),
    ExecutableProduct("out123", :out123),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
