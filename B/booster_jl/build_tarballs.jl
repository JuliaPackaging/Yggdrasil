# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "booster_jl"
version = v"0.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/evolbioinfo/booster.git", "a5f5044b192db7ab5572f44ef46abaea007f5ce9")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${WORKSPACE}/builddir
cd ${WORKSPACE}/builddir/
cp -r ${WORKSPACE}/srcdir/booster/* .
cd ${WORKSPACE}/srcdir/booster/src/
make;
install -D booster ${prefix}/bin/booster
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("booster", :booster)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
