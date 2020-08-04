# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LoopTools"
version = v"2.15"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.feynarts.de/looptools/LoopTools-2.15.tar.gz", "a065ffdc4fe6882aa3bb926134ba8ec875d6c0a633c3d4aa5f70db26542713f2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/LoopTools-*
export AR=ar
export RANLIB=ranlib
./configure --prefix=$prefix --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = expand_gfortran_versions(supported_platforms())
#
platforms = supported_platforms()
# platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liblooptools", :liblooptools)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
