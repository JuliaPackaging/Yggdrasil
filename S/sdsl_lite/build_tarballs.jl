# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sdsl_lite"
version = v"3.0.3"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/xxsds/sdsl-lite.git",
        "d54d38908a14745eb93fd5304fc9b2b9c2542ee9",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/sdsl-lite/
mkdir -p ${includedir}/sdsl
cp include/sdsl/* ${includedir}/sdsl
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = Product[]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
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
)
