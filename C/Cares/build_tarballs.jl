# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Cares"
version = v"1.18.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://c-ares.org/download/c-ares-$(version).tar.gz",
                  "1a7d52a8a84a9fbffb1be9133c0f6e17217d91ea5a6fa61f6b4729cda78ebbcf"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/c-ares-*/

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install

install_license ../LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("acountry", :acountry),
    ExecutableProduct("adig", :adig),
    ExecutableProduct("ahost", :ahost),
    LibraryProduct("libcares", :libcares)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
