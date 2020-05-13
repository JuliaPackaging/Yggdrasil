# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "coordgenlibs"
version = v"1.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mojaie/coordgenlibs.git", "d8aacab47875a6f3c6da5fda24b53910358563be"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/coordgenlibs
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DCOORDGEN_BUILD_TESTS=OFF -DCOORDGEN_BUILD_EXAMPLE=OFF
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libcoordgen", :libcoordgen)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
