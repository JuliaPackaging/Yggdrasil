using BinaryBuilder

name = "HelloWorldGo"
version = v"1.0.5"

# No sources, we're just building the testsuite
sources = [
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${prefix}/bin
go build -o ${prefix}/bin/hello_world${exeext} /usr/share/testsuite/go/hello_world/hello_world.go
install_license /usr/share/licenses/MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("hello_world", :hello_world),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :go], julia_compat="1.6")
