# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mxml"
version = v"4.0.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/michaelrsweet/mxml.git", "0d5afc4278d7a336d554602b951c2979c3f8f296")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd mxml/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make 
make install
chmod 666 /workspace/destdir/lib/pkgconfig/mxml4.pc
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmxml4", :libmxml)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
