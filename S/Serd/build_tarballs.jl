# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Serd"
# <-- this is a lie, we're building v0.30.10, but we need to bump version to build for julia v1.6
version_fake = v"0.30.11"
version = v"0.30.10"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://download.drobilla.net/serd-$(version).tar.bz2", "affa80deec78921f86335e6fc3f18b80aefecf424f6a5755e9f2fa0eb0710edf")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/serd*/

install_license COPYING
./waf configure --prefix=$prefix
./waf
./waf install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libserd-0", "serd"], :libserd)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version_fake, sources, script, platforms, products, dependencies, julia_compat="1.6")
