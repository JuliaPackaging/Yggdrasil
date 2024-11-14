using BinaryBuilder
using Pkg

name = "taskwarrior"
version = v"3.2.0"

sources = [
    GitSource("https://github.com/GothenburgBitFactory/taskwarrior", "7a092bea037517be4dc839ee8141b8d6b00738eb")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/taskwarrior/

apk del cmake

mkdir build
cd build

cmake .. -B build \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("task", :task),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Needs at least CMake 3.22, BB image has 3.21 currently
    HostBuildDependency("CMake_jll")
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.7")

