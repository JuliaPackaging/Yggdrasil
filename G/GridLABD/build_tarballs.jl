# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GridLABD"
version = v"5.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/gridlab-d/gridlab-d.git", "1b2e463d3c149e999a2c5f04213477f545e01dc6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gridlab-d/

git submodule update --init

mkdir cmake-build
cd cmake-build/

cmake -S ${WORKSPACE}/srcdir/gridlab-d -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_BUILD_TYPE=Release
cmake --build . -j${nproc} --target install

mkdir ${prefix}/share/licenses
cp ${WORKSPACE}/srcdir/gridlab-d/LICENSE ${prefix}/share/licenses/

exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("gridlabd", :gridlabd)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")
