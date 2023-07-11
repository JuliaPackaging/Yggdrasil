# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MDLovoFit"
version = v"20.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/m3g/MDLovoFit.git", "34f34b56af4f90bf065a8570981f6debb26570af")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd MDLovoFit/
make
cd bin
install -Dvm 755 "mdlovofit" "${bindir}/mdlovofit${exeext}"
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("mdlovofit", :mdlovofit)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
