# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "pugixml"
version = v"1.14.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://github.com/zeux/pugixml/releases/download/v1.14/pugixml-1.14.tar.gz",
                  "2f10e276870c64b1db6809050a75e11a897a8d7456c4be5c6b2e35a11168a015")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pugixml*
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libpugixml", :libpugixml)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
