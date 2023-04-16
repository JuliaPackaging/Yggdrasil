# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HSL"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ralna/JuliaHSL.git", "3461aed2e62f6588098692891403d8737407131c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/JuliaHSL/dummy
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
