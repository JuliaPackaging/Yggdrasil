# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LuaJIT"
version = v"2.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/LuaJIT/LuaJIT/archive/refs/heads/v$(version).zip", "9f06038cc7b74672a479cbbfc4a7560ea35b2776fffa85358de4e2fbbb3d6dfe")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/LuaJIT-*
make
make install DESTDIR=/workspace/destdir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms();


# The products that we will ensure are always built
products = [
    LibraryProduct("libluajit-5.1", :libluajit, "usr/local/lib"),
    ExecutableProduct("luajit-2.1.0-beta3", :luajit, "usr/local/bin")
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
```
