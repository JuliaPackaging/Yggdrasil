# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CLIME"
version = v"1.3.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/usqcd-software/c-lime.git", "d191881d845b6074b4e5b106d9c604cef599edc4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd c-lime/
./autogen.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("lime_pack", :lime_pack),
    ExecutableProduct("lime_extract_record", :lime_extract_record),
    ExecutableProduct("lime_extract_type", :lime_extract_type),
    ExecutableProduct("lime_unpack", :lime_unpack),
    ExecutableProduct("lime_contents", :lime_contents)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
