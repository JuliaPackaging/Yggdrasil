using BinaryBuilder

name = "licensecheck"
version = v"0.3.1"

sources = [
    GitSource("https://github.com/google/licensecheck",
              "16aaea36649f556bae5a5ee972c247f58a0de1c4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/licensecheck/
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("licensecheck", :licensecheck),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go])
