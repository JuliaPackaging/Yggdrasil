using BinaryBuilder

name = "zed"
version = v"1.15.0"

# Collection of sources
sources = [
    GitSource("https://github.com/brimdata/zed", "2a487ee2a63ed09700bb26f70f08324244227cc2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zed
install_license LICENSE.txt
make build
mkdir -p ${bindir}
cp -r dist/. ${bindir}/.
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> wordsize(p) > 32, supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("zed", :zed),
    ExecutableProduct("zq", :zq),
    ExecutableProduct("gentoken", :gentoken),
    ExecutableProduct("mockzui", :mockzui),
    ExecutableProduct("zc", :zc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go], julia_compat="1.6")
