# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libcint"
version = v"3.0.20"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sunqm/libcint.git", "34108d98a0d7f9836c2d218a6ed0e0ba7efff84f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libcint/

mkdir build && cd build

cmake .. -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBLAS_LIBRARIES="-lopenblas"

make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("x86_64", "macos"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libcint", :libcint)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
