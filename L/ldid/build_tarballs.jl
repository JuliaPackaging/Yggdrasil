# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ldid"
version = v"2.1.4" # <-- Fake version to build with new OpenSSL compat bounds

# Collection of sources required to build ldid
sources = [
    GitSource("https://github.com/staticfloat/ldid.git",
              "da986b68406ca82b82245b2ffe7a25412fa93575")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ldid*/
make INSTALLPREFIX=${prefix} -j${nproc} CFLAGS="-O3 -fPIC"
make INSTALLPREFIX=${prefix} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(filter(!Sys.iswindows, supported_platforms()))

# The products that we will ensure are always built
products = [
    ExecutableProduct("ldid", :ldid),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libplist_jll"),
    Dependency("OpenSSL_jll"; compat="3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
