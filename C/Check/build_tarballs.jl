# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Check"
version = v"0.15.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libcheck/check/releases/download/0.15.1/check-0.15.1.tar.gz", "c1cc3d64975c0edd8042ab90d881662f1571278f8ea79d8e3c2cc877dac60001")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd check-0.15.1
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcheck", :libcheck)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
