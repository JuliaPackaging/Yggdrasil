# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TtH"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://hutchinson.belmont.ma.us/tth/tth-noncom/tth_C.tgz", "83c1f39fbf3377fb43e3d01d042302fa91f8758aa9acc10e22fe8af140f0126c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tth_C
mkdir -p ${bindir}
gcc -o ${bindir}/tth${exeext} tth.c
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
