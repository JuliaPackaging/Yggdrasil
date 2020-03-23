# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "kcp_jll"
version = v"1.5.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/skywind3000/kcp.git", "87c0e6a92bb7d8b49937522cdd5844905d58d8e6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd kcp/
gcc -O4 -fPIC -c ikcp.c 
gcc -shared ikcp.o -o libkcp.so
cd $WORKSPACE/srcdir
mv kcp/libkcp.so ../destdir/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libkcp", :libkcp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
