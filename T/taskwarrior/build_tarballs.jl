using BinaryBuilder
using Pkg

name = "taskwarrior"
version = v"3.1.0"

sources = [
    GitSource("https://github.com/GothenburgBitFactory/taskwarrior", "5c6cc3e5229676655e93264e24a146a26b980e45")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/taskwarrior/

mkdir build
cd build

cmake .. -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=$prefix
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("task", :task),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.7")

