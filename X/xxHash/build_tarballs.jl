# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "xxHash"
version = v"0.8.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Cyan4973/xxHash.git", "e626a72bc2321cd320e953a0ccf1584cad60f363"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xxHash/
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    cmake_unofficial
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libxxhash", :libxxhash)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
