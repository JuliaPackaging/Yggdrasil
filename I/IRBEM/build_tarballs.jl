# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "IRBEM"
version = v"5.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/PRBEM/IRBEM.git", "e7cecb00caf97bb6357f063d2ba1aa76d71a3705")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd IRBEM/
make -j${nproc} all
make install
mkdir -p ${libdir}
cp -L ./libirbem.so ${libdir}/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; )
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libirbem", :libirbem)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
