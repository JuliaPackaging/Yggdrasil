# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "alsa"
version = v"1.2.11"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.alsa-project.org/files/pub/lib/alsa-lib-1.2.11.tar.bz2",
                  "9f3f2f69b995f9ad37359072fbc69a3a88bfba081fc83e9be30e14662795bb4d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/alsa-lib*/
./configure --prefix=${prefix} --with-configdir=/usr/share/alsa --with-plugindir=/usr/lib/alsa-lib --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(Sys.islinux, supported_platforms(;experimental=true))

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
