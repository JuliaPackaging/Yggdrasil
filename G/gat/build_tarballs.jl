using BinaryBuilder

name = "gat"
version = v"0.31.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/koki-develop/gat.git", "f4ad44169fcf08177edf1eb604eab966b4b61b0a"; tag="v$(version)"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/gat
go build -o "${bindir}/gat${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("gat", :gat)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:go, :c])
