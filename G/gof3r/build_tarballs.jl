using BinaryBuilder

name = "s3gof3r"

version = v"0.5.0"
# Collection of sources required to build pprof
sources = [
    GitSource("https://github.com/rlmcpherson/s3gof3r", "31603a0dc94aefb822bfe2ceea75a6be6013b445"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/s3g/gof3r
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("s3gof3r", :s3gof3r),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go])
