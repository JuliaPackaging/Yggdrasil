# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Imath"
version = v"3.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/AcademySoftwareFoundation/Imath/archive/refs/tags/v3.0.1.tar.gz", "9cd984bb6b0a9572dd4a373b1fab60bc4c992a52ec5c68328fe0f48f194ba3c0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Imath*
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DBUILD_TESTING=OFF \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libImath-3_0", :libImath)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
