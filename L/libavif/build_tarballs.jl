# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "libavif"
version = v"1.4.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AOMediaCodec/libavif", "c5240fc79fe5c2407e10afd35f5505ef6333ea49"; tag="v$(version)"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libavif

# We need cmake 3.22
apk del cmake

cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DAVIF_CODEC_AOM=SYSTEM \
    -DAVIF_CODEC_DAV1D=SYSTEM \
    -DAVIF_JPEG=SYSTEM \
    -DAVIF_LIBXML2=SYSTEM \
    -DAVIF_ZLIBPNG=SYSTEM
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libavif", :libavif),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("CMake_jll"),
    Dependency("JpegTurbo_jll"; compat="3.2.1"),
    Dependency("XML2_jll"; compat="~2.13.6"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("dav1d_jll"; compat="1.5.4"),
    Dependency("libaom_jll"; compat="3.15.3"),
    Dependency("libpng_jll"; compat="1.6.59"),
    Dependency("libyuv_jll"; compat="0.1.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
