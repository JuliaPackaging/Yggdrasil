# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "sgtsnepi"
version = v"3.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/fcdimitr/sgtsnepi.git", "6e31d1f214986e9d884f539811daa7fb0584e4bb")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sgtsnepi/
meson --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release build
cd build/
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis( supported_platforms() )


# The products that we will ensure are always built
products = [
    LibraryProduct("libsgtsnepi", :libsgtsnepi)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", clang_use_lld=false)
