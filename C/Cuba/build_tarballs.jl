# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Collection of sources required to build Cuba
name = "Cuba"
version = v"4.2a"
sources = [
    "https://github.com/giordano/cuba/archive/7f3613d28881cf984830e04282a483e7fe64e91a.tar.gz" =>
    "606fa27858bf93ce78af3c139d0c450555bff6244758faae6b542df3a04faf95",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cuba-*/
./configure --prefix=${prefix} --host=${target}
make -j${nproc} shared
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcuba", :libcuba)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
