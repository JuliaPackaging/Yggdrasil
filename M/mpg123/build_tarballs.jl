# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "mpg123"
version = v"1.29.3"

# Collection of sources required to build mpg123
sources = [
    ArchiveSource("https://downloads.sourceforge.net/sourceforge/mpg123/mpg123-$(version).tar.bz2",
                  "963885d8cc77262f28b77187c7d189e32195e64244de2530b798ddf32183e847"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mpg123-*/
sed -i "s/ -ffast-math//" configure
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-int-quality
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
