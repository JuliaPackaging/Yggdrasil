# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libwebp"
version = v"1.0.31"

# Collection of sources required to build libwebp
sources = [
    GitSource("https://github.com/webmproject/libwebm", "6745fd29e0245fc584b0bb9f65018ea2366fe7fb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libwebm
cmake -B build \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DENABLE_SAMPLE_PROGRAMS=OFF
cmake --build build --parallel ${njobs}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmkvmuxer", :libmkvmuxer),
    LibraryProduct("libmkvparser", :libmkvparser),
    LibraryProduct("libwebm", :libwebm),
    LibraryProduct("libwebmts", :libwebmts),
    LibraryProduct("libwebvtt_common", :libwebvtt_common),
    ExecutableProduct("webm2pes", :webm2pes),
    ExecutableProduct("webm2ts", :webm2ts),
    ExecutableProduct("webm_info", :webm_info),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
