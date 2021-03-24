# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libblastrampoline"
version = v"3.0.3"

# Collection of sources required to build Libtiff
sources = [
    GitSource("https://github.com/staticfloat/libblastrampoline",
              "7b502b7bb5d4663df4a928d0f605924cd1a35c1a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libblastrampoline/src

make -j${nproc} prefix=${prefix} install
install_license /usr/share/licenses/MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libblastrampoline", :libblastrampoline)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
