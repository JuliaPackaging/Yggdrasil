# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DAQP"
version = v"0.5.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/darnstrom/daqp.git", "5a15a3d16731d3d50f867218c1b281567db556fd")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/daqp
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="-std=gnu99" \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libdaqp", :libdaqp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
