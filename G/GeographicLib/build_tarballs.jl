# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GeographicLib"
version = v"1.52.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://sourceforge.net/projects/geographiclib/files/distrib/GeographicLib-1.52.tar.gz", "5d4145cd16ebf51a2ff97c9244330a340787d131165cfd150e4b2840c0e8ac2b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd GeographicLib-*
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("GeodesicProj", :GeodesicProj),
    ExecutableProduct("Gravity", :Gravity),
    LibraryProduct("libGeographic", :libGeographic),
    ExecutableProduct("MagneticField", :MagneticField),
    ExecutableProduct("CartConvert", :CartConvert),
    ExecutableProduct("GeodSolve", :GeodSolve),
    ExecutableProduct("GeoidEval", :GeoidEval),
    ExecutableProduct("ConicProj", :ConicProj),
    ExecutableProduct("RhumbSolve", :RhumbSolve),
    ExecutableProduct("TransverseMercatorProj", :TransverseMercatorProj),
    ExecutableProduct("Planimeter", :Planimeter),
    ExecutableProduct("GeoConvert", :GeoConvert)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
