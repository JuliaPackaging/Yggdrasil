# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "xtensor_io"
version = v"0.13.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xtensor-stack/xtensor-io", "ffada938383b0f24c9e0b07cea7d5780057e1d96"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xtensor-io

# There is a known problem with HighFive, apparently a HighFive issue.
# HighFive is close to releasing version 3.0.0, we will include it then.
# An alternative would be to use an older version of HighFive.
# Apparently 2.1.1 works, 2.2.2 doesn't.
# -DHAVE_HighFive=ON
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DDOWNLOAD_GBENCHMARK=OFF \
    -DHAVE_Blosc=ON \
    -DHAVE_OIIO=ON \
    -DHAVE_ZLIB=ON
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = Product[
    # This is a header-only library without any binary products
    FileProduct("include/xtensor-io/xtensor-io.hpp", :xtensor_io),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # BuildDependency("HighFive_jll"),
    BuildDependency("xtensor_jll"),
    BuildDependency("xtl_jll"),
    Dependency("Blosc_jll"; compat="1.21.1"),
    # Dependency("HDF5_jll"; compat="~1.14.0"),
    Dependency("OpenImageIO_jll"; compat="2.5.11"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
