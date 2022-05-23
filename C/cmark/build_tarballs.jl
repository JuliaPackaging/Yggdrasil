# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cmark"
version = v"0.30.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/commonmark/cmark.git", "a8da5a2f252b96eca60ae8bada1a9ba059a38401")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cmark/
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcmark", :libcmark),
    ExecutableProduct("cmark", :cmark)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
