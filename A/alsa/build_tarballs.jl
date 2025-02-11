# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "alsa"
version = v"1.2.13"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.alsa-project.org/files/pub/lib/alsa-lib-$(version).tar.bz2",
                  "8c4ff37553cbe89618e187e4c779f71a9bb2a8b27b91f87ed40987cc9233d8f6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/alsa-lib*
autoreconf -fiv
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(Sys.islinux, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libasound", :libasound),
    LibraryProduct("libatopology", :libatopology),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

