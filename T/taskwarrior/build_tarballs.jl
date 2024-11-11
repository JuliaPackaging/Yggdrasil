using BinaryBuilder

name = "taskwarrior"
version = v"3.1.0"

sources = [
    GitSource("https://github.com/GothenburgBitFactory/taskwarrior", "5c6cc3e5229676655e93264e24a146a26b980e45")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/taskwarrior/
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("task", :task),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")

