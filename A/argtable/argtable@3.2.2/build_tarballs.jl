# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.

include("../common.jl")

version = v"3.2.2"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/argtable/argtable3.git",
        "55c4f6285e2f9b2f0cc96ae8212b7b943547c3dd",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/argtable*
install_license LICENSE
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude = Sys.iswindows)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [LibraryProduct("libargtable3", :libargtable3)]

# Build the tarballs, and possibly a `build.jl` as well.
build_argtable(version, sources, script, platforms, products)
