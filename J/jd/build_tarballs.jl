# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "jd"
version = v"1.8.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/josephburnett/jd.git", "11eae3c9ffb1dd32796ca741691bf4733a27dfa4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/jd

go build -o ${bindir}/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    ExecutableProduct("jd", :jd)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:go, :c])
