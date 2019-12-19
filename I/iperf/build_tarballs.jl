# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "iperf"
version = v"3.7.0"

# Collection of sources required to complete build
sources = [
    "https://github.com/esnet/iperf/archive/3.7.tar.gz" =>
    "c349924a777e8f0a70612b765e26b8b94cc4a97cc21a80ed260f65e9823c8fc5",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/iperf-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-profiling
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> !isa(p, Windows), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libiperf", :libiperf),
    ExecutableProduct("iperf3", :iperf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

