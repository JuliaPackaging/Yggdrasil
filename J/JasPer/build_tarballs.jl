# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "JasPer"
version = v"4.2.9"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jasper-software/jasper", "63e106c80eb72af9fd4fa28772499ab0138b9994"),
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/jasper*

# Note: the build directory must not be named `build`. The JasPer source tree
# contains a file `build/build`, which then collides with the generated
# `${CMAKE_CURRENT_BINARY_DIR}/build/pkgconfig/jasper.pc`.
cmake -Bjll_build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJAS_ENABLE_DOC=false \
    -DJAS_ENABLE_OPENGL=false \
    -DALLOW_IN_SOURCE_BUILD=true \
    -DJAS_STDC_VERSION=201112L \
    -DCMAKE_BUILD_TYPE=Release

cmake --build jll_build --parallel ${nproc}
cmake --install jll_build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libjasper", :libjasper),
    ExecutableProduct("imginfo", :imginfo),
    ExecutableProduct("jasper", :jasper),
    ExecutableProduct("imgcmp", :imgcmp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("JpegTurbo_jll"; compat="3.2.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
