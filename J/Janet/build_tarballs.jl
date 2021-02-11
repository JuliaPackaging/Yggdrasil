using BinaryBuilder, Pkg

name = "Janet"
version = v"1.15.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/janet-lang/janet/archive/v1.15.0.tar.gz",
                  "e2cf16b330e47c858a675ac79b5a0af83727ff041efcb133a80f36bedfae57c4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/janet-*/
export PREFIX = $WORKSPACE/w-*/usr/local
make 
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("janet", :janet),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    ]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
