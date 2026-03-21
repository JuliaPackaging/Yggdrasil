# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "very_nauty"
version = v"1.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaGraphs/very_nauty.git", "f0680a2877fe25b0e59d90b24bad370f02525093")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/very_nauty/
mkdir -p ${libdir}
cc -shared -fPIC -Wall -O3 -o "${libdir}/libvn_graph.${dlext}" vn_graph.c
install -Dvm 644 vn_graph.h -t ${includedir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libvn_graph", :libvn_graph)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
