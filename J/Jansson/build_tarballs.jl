using BinaryBuilder

name = "Jansson"
version = v"2.13.1"

# Collection of sources required to build ZMQ
sources = [
    GitSource("https://github.com/akheron/jansson.git", "e9ebfa7e77a6bee77df44e096b100e7131044059"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/jansson

autoreconf -fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libjansson", :libjansson),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
