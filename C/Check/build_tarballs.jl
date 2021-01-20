# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Check"
version = v"0.15.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libcheck/check/releases/download/0.15.2/check-0.15.2.tar.gz", "a8de4e0bacfb4d76dd1c618ded263523b53b85d92a146d8835eb1a52932fa20a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd check-0.15.2
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
install_license COPYING.LESSER
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
