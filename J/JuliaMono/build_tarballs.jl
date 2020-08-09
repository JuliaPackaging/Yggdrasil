# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "JuliaMono"
version = v"0.6"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/cormullion/juliamono",
        "5ac789e8578c2d53f5cf4e7a41365582dbc518ac",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/julia/
cp JuliaMono-*.ttf "${prefix}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("JuliaMono-Light.ttf", :juliamono_light),
    FileProduct("JuliaMono-Regular.ttf", :juliamono_regular),
    FileProduct("JuliaMono-Medium.ttf", :juliamono_medium),
    FileProduct("JuliaMono-Bold.ttf", :juliamono_bold),
    FileProduct("JuliaMono-ExtraBold.ttf", :juliamono_extrabold),
    FileProduct("JuliaMono-Black.ttf", :juliamono_black),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
