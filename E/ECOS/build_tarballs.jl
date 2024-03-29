using BinaryBuilder

# To distinguish between upstream changes and changes to the JLL, we use:
#     version = 100 * upstream version + offset
# See C/Coin-OR/coin-or-common.jl for more details.
version = v"200.0.800"

# Collection of sources required to build ECOSBuilder
sources = [
    GitSource("https://github.com/embotech/ecos.git", "3b98fe0376ceeeb8310a06694b0a84ac59920f3f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ecos*
make shared

mkdir -p ${libdir}
cp libecos.${dlext} ${libdir}
cp -r include ${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libecos", :libecos)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(
    ARGS,
    "ECOS",
    version,
    sources,
    script,
    platforms,
    products,
    dependencies,
    julia_compat = "1.6",
)
