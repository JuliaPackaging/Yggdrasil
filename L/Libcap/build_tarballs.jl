# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libcap"
version = v"2.27"

# Collection of sources required to build libcap
sources = [
    "https://kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-$(version.major).$(version.minor).tar.xz" =>
    "dac1792d0118bee6aae6ba7fb93ff1602c6a9bda812fd63916eee1435b9c486a",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libcap-*/
make -j${nproc} BUILD_CC="${CC_FOR_BUILD}"
make prefix=${prefix} lib=/lib RAISE_SETFCAP=no install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = [p for p in supported_platforms() if p isa Linux]

# The products that we will ensure are always built
products = [
    LibraryProduct("libcap", :libcap),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Attr_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
