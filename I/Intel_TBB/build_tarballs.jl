# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Intel_TBB"
version = v"2021.9.0"

# Collection of sources required to build hwloc
sources = [
    GitSource("https://github.com/oneapi-src/oneTBB", "a00cc3b8b5fb4d8115e9de56bf713157073ed68c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/oneTBB
rm -f /usr/share/cmake/Modules/Compiler/._*.cmake
cmake -B build -S . \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DTBB_STRICT=OFF \
    -DTBB_TEST=OFF
cmake --build build --parallel ${nproc}
cmake --build build --parallel ${nproc} --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libtbb", :libtbb),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
