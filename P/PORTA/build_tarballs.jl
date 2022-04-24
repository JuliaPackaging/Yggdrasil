# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PORTA"
version = v"1.4.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/bdoolittle/julia-porta.git", "41a7653c0df6dc0fe738aa4a2347096f27d391c0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/julia-porta
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("xporta", :xporta),
    LibraryProduct("libporta", :libporta),
    ExecutableProduct("valid", :valid)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
