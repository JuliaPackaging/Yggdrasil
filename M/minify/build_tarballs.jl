# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder

name = "minify"
version = v"2.12.7"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/tdewolff/minify.git",
        "bf2187d141bb46a807174779f6cbd3a16eb680f1",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/minify
install_license LICENSE
cd ${WORKSPACE}/srcdir/minify/cmd/minify
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [ExecutableProduct("minify", :minify)]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    compilers = [:c, :go],
    julia_compat = "1.6",
)
