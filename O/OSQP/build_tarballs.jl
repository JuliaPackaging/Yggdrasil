# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# To distinguish between upstream changes and changes to the JLL, we use:
#     version = 100 * upstream version + offset
# See C/Coin-OR/coin-or-common.jl for more details.
version = v"0.600.200"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/osqp/osqp.git",
        "f9fc23d3436e4b17dd2cb95f70cfa1f37d122c24",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/osqp
git submodule update --init --recursive
mkdir build
cd build/
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libqdldl", :qdldl),
    LibraryProduct("libosqp", :osqp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS,
    "OSQP",
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.6",
)
