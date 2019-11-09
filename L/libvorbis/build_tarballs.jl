# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "libvorbis"
version = v"1.3.6"

# Collection of sources required to build libvorbis
sources = [
    "https://downloads.xiph.org/releases/vorbis/libvorbis-$(version).tar.xz" =>
    "af00bb5a784e7c9e69f56823de4637c350643deedaf333d0fa86ecdba6fcb415",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libvorbis-*
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# The products that we will ensure are always built
products = [
    LibraryProduct("libvorbis", :libvorbis),
    LibraryProduct("libvorbisenc", :libvorbisenc),
    LibraryProduct("libvorbisfile", :libvorbisfile),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Ogg_jll",
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
