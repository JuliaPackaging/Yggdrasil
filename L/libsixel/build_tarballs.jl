# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsixel"
version = v"1.10.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libsixel/libsixel.git", "37026b01a0bd38634ae0a8c5017bd4671101fe08"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsixel

meson --cross-file="${MESON_TARGET_TOOLCHAIN}" build
cd build

ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsixel", :libsixel)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libpng_jll"),
    Dependency("JpegTurbo_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6")
