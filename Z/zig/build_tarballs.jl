using BinaryBuilder

name = "zig"
version = v"0.10.0"

sources = [
    GitSource("https://github.com/ziglang/zig.git",
              "99b954b9ce1cf096490a1e4bb4d316420a13c297"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/zig
mkdir build
cd build
cmake ..
make install
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("zig", :zig),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6", preferred_gcc_version=v"9")
