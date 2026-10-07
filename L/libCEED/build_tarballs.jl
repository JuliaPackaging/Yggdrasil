# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libCEED"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/CEED/libCEED.git", "8a374e8d5d8d33fd19ce69a93026384ec1046a86"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libCEED*
make -j${nproc} OPT='$(MARCHFLAG) $(OPT.$(CC_VENDOR)) $(OMP_SIMD_FLAG) -O3' MEMCHK=0 CC_VENDOR=gcc
make install OPT='$(MARCHFLAG) $(OPT.$(CC_VENDOR)) $(OMP_SIMD_FLAG) -O3' MEMCHK=0 CC_VENDOR=gcc
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude=Sys.iswindows)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libceed", :libceed)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
