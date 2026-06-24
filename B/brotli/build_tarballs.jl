# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "brotli"
version = v"1.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/brotli", "028fb5a23661f123017c060daa546b55cf4bde29"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/brotli
cmakeflags=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_C_STANDARD=99
    -DCMAKE_C_STANDARD_REQUIRED=ON
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
)
cmake -Bbuild ${cmakeflags[@]}
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
