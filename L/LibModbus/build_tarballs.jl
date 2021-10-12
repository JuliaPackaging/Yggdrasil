# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibModbus"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/stephane/libmodbus.git", "f9fe3b0a5343f7fbb3f5c74196bd0fce88df39d5")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libmodbus/
./autogen.sh 
./configure --prefix=$prefix --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license COPYING.LESSER
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmodbus", :libmodbus)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
