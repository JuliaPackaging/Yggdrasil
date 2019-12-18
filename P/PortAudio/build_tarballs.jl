using BinaryBuilder

# Collection of sources required to build Pixman
name = "PortAudio"
version = v"19.06.0"
sources = [
    "http://www.portaudio.com/archives/pa_stable_v190600_20161030.tgz" =>
    "f5a21d7dcd6ee84397446fa1fa1a0675bb2e8a4a6dceb4305a8404698d8d1513",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/portaudio*/

./configure --disable-mac-universal --prefix=${prefix} --host=${target} --build=${MACHTYPE}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libportaudio", :libportaudio),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
product_hashes = build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
