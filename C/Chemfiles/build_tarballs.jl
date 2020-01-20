# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Chemfiles"
version = v"0.9.2"

# Collection of sources required to complete build
sources = [
    "https://github.com/chemfiles/chemfiles/archive/$version.tar.gz" =>
    "f0a40c8934cffdc8321bed79ded4cb4de5d5366d1f503a95467e294384521e82",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/chemfiles-*/
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON ..
atomic_patch -p1 ../../patches/fileno_posix.patch
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libchemfiles", :libchemfiles)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
