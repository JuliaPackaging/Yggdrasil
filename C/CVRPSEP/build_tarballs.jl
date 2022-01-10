# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CVRPSEP"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/chkwon/CVRPSEP.git", "c4d1720ffafcc174e39f65c7a90146cb82b68e44")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CVRPSEP/
autoreconf -fiv
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcvrpsep", :libcvrpsep)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
