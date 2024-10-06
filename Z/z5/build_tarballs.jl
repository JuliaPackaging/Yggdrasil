# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "z5"
version = v"2.0.18"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/constantinpape/z5", "c77f42e222ef91bd8cd4551cf9bb6b07b0adc28a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/z5

cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_Z5PY=OFF \
    -DWITH_BLOSC=ON \
    -DWITH_BZIP2=ON \
    -DWITH_LZ4=ON \
    -DWITH_MARRAY=ON \
    -DWITH_XZ=ON \
    -DWITH_ZLIB=ON
# Other possible options:
#     WITH_GCS
#     WITH_S3

cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    # This is a header-only library without any binary products
    FileProduct("include/z5/z5.hxx", :z5)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("nlohmann_json_jll"),
    BuildDependency("xsimd_jll"),
    BuildDependency("xtensor_jll"),
    BuildDependency("xtl_jll"),
    Dependency("Blosc_jll"; compat="1.21.1"),
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("Lz4_jll"; compat="1.9.3"),
    Dependency("XZ_jll"; compat="5.2.5"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
