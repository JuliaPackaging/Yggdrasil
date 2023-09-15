# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "nss_mdns"
version = v"0.15.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lathiat/nss-mdns.git", "4b3cfe818bf72d99a02b8ca8b8813cb2d6b40633")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd nss-mdns
./bootstrap.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libnss_mdns", :libnss_mdns),
    LibraryProduct("libnss_mdns4_minimal", :libnss_mdns4_minimal),
    LibraryProduct("libnss_mdns4", :libnss_mdns4),
    LibraryProduct("libnss_mdns_minimal", :libnss_mdns_minimal),
    LibraryProduct("libnss_mdns6", :libnss_mdns6),
    LibraryProduct("libnss_mdns6_minimal", :libnss_mdns6_minimal)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
