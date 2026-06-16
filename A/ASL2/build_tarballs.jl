# solvers2.tgz is the multithreaded variant of the AMPL Solver Library, in
# which evaluations operate on a given EvalWorkspace, so that distinct
# workspaces may evaluate concurrently from different threads.

using BinaryBuilder

name = "ASL2"
version = v"2025.11.21"

# Sources required to build ASL2.
sources = [
    GitSource("https://github.com/ampl/asl",
              "3d477ba78a3392b8b7b05a2fd843ae7f9df70252")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/asl
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON
cmake --build build --parallel
cmake --install build

install_license LICENSE
"""

platforms = supported_platforms()

# The products that we will ensure are always built.
# The library is named libasl2 so that ASL_jll and ASL2_jll can coexist in
# the same process; the asl_* entry points keep their names, since each JLL
# resolves symbols within its own library handle.
products = [
    LibraryProduct("libasl2", :libasl2)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat = "1.6")
