# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibModbus"
version = v"3.1.10"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/stephane/libmodbus.git", "b25629bfb508bdce7d519884c0fa9810b7d98d44")
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
