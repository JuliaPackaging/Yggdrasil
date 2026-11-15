# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PicoHTTPParser"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/h2o/picohttpparser.git", "f8326098f63eefabfa2b6ec595d90e9ed5ed958a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p ${libdir}
${CC} -shared -O2 -o ${libdir}/libpicohttpparser.${dlext} -fPIC picohttpparser/picohttpparser.c
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libpicohttpparser", :libpicohttpparser)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
