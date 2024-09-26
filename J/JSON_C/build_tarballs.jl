# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "JSON_C"
version = v"0.17.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://s3.amazonaws.com/json-c_releases/releases/json-c-0.17.tar.gz", "b8d80a1ddb718b3ba7492916237bbf86609e9709fb007e7f7d4322f02341a4c6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd json-c-0.17
cmake -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libjson-c", :libjson_c)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
