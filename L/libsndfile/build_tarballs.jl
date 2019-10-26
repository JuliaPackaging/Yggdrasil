# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libsndfile"
version = v"1.0.28"

# Collection of sources required to build
sources = [
    "http://www.mega-nerd.com/libsndfile/files/libsndfile-$(version).tar.gz" =>
    "1ff33929f042fa333aed1e8923aa628c3ee9e1eb85512686c55092d1e5a9dfa9"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsndfile-*/
CFLAGS="-I${prefix}/include" ./configure --prefix=$prefix --host=$target --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsndfile", :libsndfile),
    ExecutableProduct("sndfile-cmp", :sndfile_cmp),
    ExecutableProduct("sndfile-concat", :sndfile_concat),
    ExecutableProduct("sndfile-convert", :sndfile_convert),
    ExecutableProduct("sndfile-deinterleave", :sndfile_deinterleave),
    ExecutableProduct("sndfile-info", :sndfile_info),
    ExecutableProduct("sndfile-interleave", :sndfile_interleave),
    ExecutableProduct("sndfile-metadata-get", :sndfile_metadata_get),
    ExecutableProduct("sndfile-metadata-set", :sndfile_metadata_set),
    ExecutableProduct("sndfile-play", :sndfile_play),
    ExecutableProduct("sndfile-salvage", :sndfile_salvage)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "FLAC_jll",
    "Ogg_jll",
    "libvorbis_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
