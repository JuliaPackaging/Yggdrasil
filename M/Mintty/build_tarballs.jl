using BinaryBuilder

name = "Mintty"
version = v"3.1.0"

# Collection of sources required to build Wayland
sources = [
    "https://github.com/mintty/mintty/archive/$(version).tar.gz" =>
    "3dcb536a40298d454652011bc829a905330ef93e740e096331473d443d858367",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mintty-*/
make -j${nproc}
cp src/mintty.exe ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Windows]

# The products that we will ensure are always built
products = [
    ExecutableProduct("mintty", :mintty),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
