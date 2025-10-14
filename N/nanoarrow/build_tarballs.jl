# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "nanoarrow"
version = v"0.7.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/apache/arrow-nanoarrow.git", "2cfba631b40886f1418a463f3b7c4552c8ae0dc7")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/arrow-nanoarrow
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libnanoarrow_shared", :libnanoarrow_shared),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               julia_compat="1.6")
