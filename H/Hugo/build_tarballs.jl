# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Hugo"
version = v"0.118.2"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/gohugoio/hugo.git",
        "da7983ac4b94d97d776d7c2405040de97e95c03d",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/hugo
install_license LICENSE
mkdir -p ${bindir}
CGO_ENABLED=1 go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [ExecutableProduct("hugo", :hugo)]

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
    julia_compat = "1.6",
    compilers = [:go, :c],
)

