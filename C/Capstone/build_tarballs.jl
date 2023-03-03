# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Capstone"
upstream_version = v"4.0.2"
version = v"4.0.3" # <-- This version number is a lie to build for newer platforms

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/aquynh/capstone/archive/$(upstream_version).tar.gz",
                  "7c81d798022f81e7507f1a60d6817f63aa76e489aa4e7055255f21a22f5e526a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/capstone-*/
mkdir build && cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -G Ninja \
    ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcapstone", :libcapstone),
    ExecutableProduct("cstool", :cstool)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
