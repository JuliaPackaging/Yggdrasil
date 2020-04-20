# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PORTA"
version = v"1.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/bdoolittle/julia-porta.git", "93b99656f390c2252a0142bf9a4c22f5217a42da")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p ${bindir}
make -C julia-porta/gnu-make/ CC=${CC}
cp julia-porta/gnu-make/bin/xporta${exeext} ${bindir}
cp julia-porta/gnu-make/bin/valid${exeext} ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("xporta", :xporta),
    ExecutableProduct("valid", :valid)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
