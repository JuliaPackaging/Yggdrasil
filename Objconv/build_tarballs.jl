# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Objconv"
version = v"2.49.0"

# Collection of sources required to build CMake
sources = [
    "https://github.com/staticfloat/objconv/archive/v2.49.tar.gz" =>
    "5fcdf0eda828fbaf4b3d31ba89b5011f649df3a7ef0cc7520d08fe481cac4e9f",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/objconv*/

mkdir -p ${prefix}/bin
if [[ ${target} == *mingw* ]]; then
    EXE=".exe"
fi
${CXX} ${CPPFLAGS} ${CXXFLAGS} ${LDFLAGS} -O2 -o ${prefix}/bin/objconv${EXE} src/*.cpp
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "cmake", :cmake),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

