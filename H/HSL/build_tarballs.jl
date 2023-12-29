# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HSL"
version = v"2.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ralna/libHSL.git", "299299186e081c43a471e8c3ddb00f476b08682c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libHSL/dummy
meson setup builddir --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release
meson compile -C builddir
meson install -C builddir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libhsl", :libhsl)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
