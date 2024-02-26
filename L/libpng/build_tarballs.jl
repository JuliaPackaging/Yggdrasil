# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libpng"
version = v"1.6.42"

# Collection of sources required to build libpng
sources = [
    ArchiveSource("https://sourceforge.net/projects/libpng/files/libpng16/$(version)/libpng-$(version).tar.gz",
                  "eaa27b655f2cd37a3677372d7dfc646263401ef79d4f433345f24429ec60334a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libpng-*/
mkdir build && cd build
if [[ "${target}" == aarch64-apple-darwin* ]]; then
    # Let CMake know this platform supports NEON extension
    FLAGS=(-DPNG_ARM_NEON=on)
fi
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DPNG_STATIC=OFF \
    "${FLAGS[@]}" \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libpng16", :libpng)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
