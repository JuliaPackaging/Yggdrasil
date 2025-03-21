# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gecko"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/LLNL/gecko.git", "490ab7d9b7b4e0f007e10d2af2b022b96d427fee")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gecko/
mkdir build
cmake -S ./ -B build .. \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Only support Linux and FreeBSD
platforms = expand_cxxstring_abis(supported_platforms())
filter!(p -> (Sys.islinux(p) || Sys.isfreebsd(p)), platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libgecko", :libgecko)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
