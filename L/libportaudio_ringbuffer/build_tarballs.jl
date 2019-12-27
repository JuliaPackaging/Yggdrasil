# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libportaudio_ringbuffer"
version = v"19.6.0"

# Collection of sources required to build libportaudio. Not all of these
# are used for all platforms.
sources = [
    "http://portaudio.com/archives/pa_stable_v190600_20161030.tgz" =>
    "f5a21d7dcd6ee84397446fa1fa1a0675bb2e8a4a6dceb4305a8404698d8d1513",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/portaudio*
mkdir -p ${libdir} ${prefix}/include
${CC} -g -fPIC src/common/pa_ringbuffer.c -o ${libdir}/libpa_ringbuffer.${dlext}
install -m644 src/common/pa_ringbuffer.h ${prefix}/include/
install_license "${WORKSPACE}/srcdir/portaudio/LICENSE.txt"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libpa_ringbuffer", :libpa_ringbuffer),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
