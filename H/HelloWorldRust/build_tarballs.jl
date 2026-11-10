using BinaryBuilder

name = "HelloWorldRust"
version = v"1.1.1"

# No sources, we're just building the testsuite
sources = DirectorySource[
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${bindir}
rustc -o ${bindir}/hello_world${exeext} -g /usr/share/testsuite/rust/hello_world/hello_world.rs
install_license /usr/share/licenses/MIT
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("hello_world", :hello_world),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")
