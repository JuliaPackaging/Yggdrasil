# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "libvorbis"
version = v"1.3.6"
# Collection of sources required to build imagemagick

sources = [
    "https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.6.tar.xz" =>
    "af00bb5a784e7c9e69f56823de4637c350643deedaf333d0fa86ecdba6fcb415",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libvorbis-1.3.6/
./configure --prefix=$prefix --host=$target
make -j${ncore}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# The products that we will ensure are always built
products = [
    LibraryProduct("libvorbis", :libvorbis),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Ogg_jll"
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
