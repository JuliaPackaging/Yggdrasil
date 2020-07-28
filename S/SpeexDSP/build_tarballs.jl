# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SpeexDSP"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.osuosl.org/pub/xiph/releases/speex/speexdsp-1.2.0.tar.gz", "682042fc6f9bee6294ec453f470dadc26c6ff29b9c9e9ad2ffc1f4312fd64771")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd speexdsp-1.2.0
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libspeexdsp", :SpeexDSP)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
