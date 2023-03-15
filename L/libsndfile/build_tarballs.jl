# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libsndfile"
version = v"1.1.0"

# Collection of sources required to build
sources = [
    ArchiveSource("https://github.com/libsndfile/libsndfile/releases/download/$(version)/libsndfile-$(version).tar.xz",
                  "0f98e101c0f7c850a71225fb5feaf33b106227b3d331333ddc9bacee190bcf41")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsndfile-*/
export CFLAGS="-I${includedir}"
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    ..
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
    ExecutableProduct("sndfile-salvage", :sndfile_salvage),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("alsa_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("FLAC_jll"; compat="~1.3.4"),
    Dependency("libvorbis_jll"),
    Dependency("Ogg_jll"),
    Dependency("Opus_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
