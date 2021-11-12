# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Pinchot"
version = v"13.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/joeynelson/pinchot-c-api.git", "cee8ff854a6c3135aa861094cf1b27dc6e01a393")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pinchot-c-api
mkdir build
cd build/
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON
make -j${nproc}
make install
install_license ../LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpinchot", :libpinchot)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
