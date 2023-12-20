# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "openbabel"
version = v"3.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/openbabel/openbabel/releases/download/openbabel-3-1-0/openbabel-$(version)-source.tar.bz2", "53ff96d53a190097d9a0d5243be2b7c97a6a844129a303e93cbe6e3aaf1723f9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd openbabel-3.1.0/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("obabel", :obabel)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
