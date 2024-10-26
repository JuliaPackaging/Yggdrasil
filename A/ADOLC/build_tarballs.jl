# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ADOLC"
version = v"2.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/coin-or/ADOL-C.git", "5ab065723fbe9cd4ff7d999ae8f5218e595cb875")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ADOL-C/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_INTERFACE=ON
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libADOLCInterface", :adolc_interface_lib),
    LibraryProduct("libadolc", :adolc_lib)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
