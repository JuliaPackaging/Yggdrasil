# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "flecs"
version = v"4.0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/SanderMertens/flecs.git", "b3ad03c391a268234c54270ccf3793c5b6ad6312")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/flecs/
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.isbsd)

# The products that we will ensure are always built
products = [
    LibraryProduct("libflecs", :libflecs)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")


