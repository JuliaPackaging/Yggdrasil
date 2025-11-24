# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "fzf"
version = v"0.61.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/junegunn/fzf.git", "2c5f239a1e7554c2182587be9794e45b721f7236")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fzf/
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("fzf", :fzf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:c, :go], julia_compat="1.6")
