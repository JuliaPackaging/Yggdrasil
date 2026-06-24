# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "zarray"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xtensor-stack/zarray", "d45928963433a5abada8131b1416b20eb8e7cecf"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zarray
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    -DZARRAY_USE_XSIMD=ON
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    # This is a header-only library without any binary products
    FileProduct("include/zarray/zarray.hpp", :zarray),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("nlohmann_json_jll"),
    Dependency("xsimd_jll"),
    Dependency("xtensor_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
