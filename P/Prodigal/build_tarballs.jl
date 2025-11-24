# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Prodigal"
version = v"2.6.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/hyattpd/Prodigal.git", "004218fbeb2cf54fe12d88ec2eede6a27d70ebf7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Prodigal
make install INSTALLDIR=${bindir} CC=cc TARGET="prodigal${exeext}"
install_license ${WORKSPACE}/srcdir/Prodigal/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    ExecutableProduct("prodigal", :prodigal)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
