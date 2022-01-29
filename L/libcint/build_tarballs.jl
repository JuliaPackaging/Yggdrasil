# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libcint"
version = v"5.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sunqm/libcint.git", "9fdd8eff6f0e1177aa1d70a85686f1b34a482cda")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libcint/

mkdir build && cd build

cmake .. -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("x86_64", "macos")
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libcint", :libcint)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
