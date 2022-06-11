# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SOLAR"
version = v"0.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/bbopt/solar.git", "37615c09482b6e8b28f430c7633b59b1fc0d1b77")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p $bindir
cd $WORKSPACE/srcdir/solar/src
make COMPILATOR="c++" LIBS="-lm" EXE="${bindir}/solar${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(;experimental=true))


# The products that we will ensure are always built
products = [
    ExecutableProduct("solar", :solar)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0", julia_compat="1.6")
