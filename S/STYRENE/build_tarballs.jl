# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "STYRENE"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/bbopt/styrene.git", "f7eb5c566cf7f152d53bbc1490d03568d00d22f1")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p $bindir
cd $WORKSPACE/srcdir/styrene/blackbox/surrogate
make COMPILATOR="c++" LIBS="-lm" EXE="${bindir}/surrogate${exeext}"
cd $WORKSPACE/srcdir/styrene/blackbox/truth
make COMPILATOR="c++" LIBS="-lm" EXE="${bindir}/truth${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(;experimental=true))


# The products that we will ensure are always built
products = [
    ExecutableProduct("surrogate", :surrogate),
    ExecutableProduct("truth", :truth)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
