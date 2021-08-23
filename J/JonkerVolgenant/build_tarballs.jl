# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "JonkerVolgenant"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/fypc/Jonker-Volgenant.git", "d4c4db3ba9353858496d27170e4a26db1ec1520a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd Jonker-Volgenant
cd src
gcc -I -Wall -std=c99 -shared -fPIC -O3 -o bipartite_assignement.so *.c
exit
cd $WORKSPACE/srcdir
install_license
logout
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
