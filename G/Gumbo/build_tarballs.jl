# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Gumbo"
version = v"0.10.1"

# Collection of sources required to complete build
#This is commit dated Jun 28, 2016 which is currently master as of Aug 5, 2020
# v0.10.1 is the last release, so we keep that version number. 
sources = [
    "https://github.com/google/gumbo-parser.git" =>
    "aa91b27b02c0c80c482e24348a457ed7c3c088e0",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gumbo-parser/
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms =  supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgumbo", :libgumbo)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

