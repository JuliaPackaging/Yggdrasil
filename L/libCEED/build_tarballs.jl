# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libCEED"
version = v"0.7.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/CEED/libCEED.git", "6134893e0067dc2a87bbbe22a551ae134ad5b885")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libCEED
make -j${nproc} MEMCHK=0 CC_VENDOR=gcc
make install MEMCHK=0 CC_VENDOR=gcc
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    LibraryProduct("libceed", :libceed)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
#build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0")
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
