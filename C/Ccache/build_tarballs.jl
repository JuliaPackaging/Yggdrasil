# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Ccache"
version = v"4.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ccache/ccache/releases/download/v$(version.major).$(version.minor)/ccache-$(version.major).$(version.minor).tar.xz",
                  "2f14b11888c39778c93814fc6843fc25ad60ff6ba4eeee3dff29a1bad67ba94f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ccache*
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nroc}
make install
install_license ../GPL-3.0.txt ../LGPL-3.0.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("ccache", :ccache),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
