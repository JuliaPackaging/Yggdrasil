# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gb"
version = v"0.17.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ederc/gb.git", "ec98ed8deeeb47e3e7bdf38eb947453bfa6b23b5")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd gb/
./autogen.sh 
./configure --enable-shared --disable-static --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gmp=${prefix}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(!Sys.iswindows, supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libgb--no-undefined", :libgb)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
