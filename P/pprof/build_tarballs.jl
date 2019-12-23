using BinaryBuilder

name = "pprof"

# PProf doesn't have proper versions yet
# so we use Go's pseudo version
# `TZ=UTC git show --quiet --date='format-local:%Y%m%d%H%M%S' --format="%cd" $hash`

hash = "f9b734f9ee64d0f5b63636a45cc77ed2744997ab"
timestamp = "20191205061153"
version = Base.VersionNumber("0.0.0-$timestamp")

# Collection of sources required to build pprof
sources = [
    "https://github.com/google/pprof.git" =>
    hash,
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pprof/
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("pprof", :pprof),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go])
