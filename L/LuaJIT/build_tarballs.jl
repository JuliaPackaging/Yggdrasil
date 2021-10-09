# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LuaJIT"
version = v"2.0.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://luajit.org/download/LuaJIT-$(version).tar.gz", "874b1f8297c697821f561f9b73b57ffd419ed8f4278c82e05b48806d30c1e979")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/LuaJIT*
make
make install DESTDIR=/workspace/destdir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libluajit-5.1", :libluajit, "usr/local/lib"),
    ExecutableProduct("luajit-$(version)", :luajit, "usr/local/bin")
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
