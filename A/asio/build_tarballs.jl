# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "asio"
version = v"1.18.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/chriskohlhoff/asio.git", "b84e6c16b2ea907dbad94206b7510d85aafc0b42"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/asio/asio
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make install
"""

# Because we are just producing a header, the same product is available for any platform
platforms = [AnyPlatform()]

# The products that we will ensure are always built (header-only: export main header so downstreams can discover include/)
products = [
    FileProduct("include/asio.hpp", :asio_hpp),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
)
