# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "zlibng"
version = v"2.0.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/zlib-ng/zlib-ng.git", "c69f78bc5e18a0f6de2dcbd8af863f59a14194f0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd zlib-ng/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DZLIB_COMPAT=ON
make install -j
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)


# The products that we will ensure are always built
products = [
    LibraryProduct("libz", :libz)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; experimental_platforms=true, julia_compat="1.6")
