# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cephes"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/Cactus-proj/cephes/releases/download/v$(version)/cephes-$(version).tar.gz",
                  "54549d5ec8560816fa6a98c048420832d337685ae739cecee56614dce032701d"),
    # GitSource("https://github.com/Cactus-proj/cephes.git",
    #           "efe835a0cb4c6c760ff6c803d1d9cfd1bfbded75"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cephes*/

cmake -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libcephes", :libcephes)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
