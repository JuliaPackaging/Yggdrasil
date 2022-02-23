# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "pugixml"
version = v"1.11.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://github.com/zeux/pugixml/releases/download/v1.11/pugixml-1.11.tar.gz", "26913d3e63b9c07431401cf826df17ed832a20d19333d043991e611d23beaa2c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pugixml*
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -S ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))


# The products that we will ensure are always built
products = [
    LibraryProduct("libpugixml", :libpugixml)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
