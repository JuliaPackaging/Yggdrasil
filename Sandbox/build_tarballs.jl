using BinaryBuilder

name = "Sandbox"
version = v"2018.08.22"

# Collection of sources required to build Ogg
sources = [
    "./source"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/

mkdir -p ${prefix}/bin
gcc -O2 -o ${prefix}/bin/sandbox *.c
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [Linux(:x86_64, :glibc)]

# The products that we will ensure are always built
products = prefix -> [
    ExecutableProduct(prefix, "sandbox", :sandbox),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
