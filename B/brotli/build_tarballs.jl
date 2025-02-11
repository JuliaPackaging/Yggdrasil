# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "brotli"
version = v"1.1.1" # Building v1.1.0, version bump to pick up riscv

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/brotli", "ed738e842d2fbdf2d6459e39267a633c4a9b2f5d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/brotli
cmake -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nprocs}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libbrotlidec", :libbrotlidec),
    LibraryProduct("libbrotlicommon", :libbrotlicommon),
    LibraryProduct("libbrotlienc", :libbrotlienc),
    ExecutableProduct("brotli", :brotli)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
