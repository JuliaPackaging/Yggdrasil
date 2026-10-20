# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "FriBidi"
version = v"1.0.17"
# FriBidi_jll v1.0.17 was already used for a rebuild of upstream v1.0.16
ygg_version = v"1.0.18"

# Collection of sources required to build FriBidi
sources = [
    GitSource("https://github.com/fribidi/fribidi.git",
              "b93119f5fdc7ea47672cc304c1455ffa6dfe7536";
              tag="v$(version)"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fribidi/
mkdir build && cd build

meson .. -Ddocs=false --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libfribidi", :libfribidi),
    ExecutableProduct("fribidi", :fribidi)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", clang_use_lld=false)
