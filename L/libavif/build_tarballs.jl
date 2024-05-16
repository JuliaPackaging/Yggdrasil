# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "libavif"
version = v"1.0.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AOMediaCodec/libavif", "d77cfece0b3e233ee4bed49dfef1e7dc451599f8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libavif
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
    Dependency("JpegTurbo_jll"),
    Dependency("XML2_jll"),
    Dependency("Zlib_jll"),
    Dependency("dav1d_jll"),
    Dependency("libaom_jll"),
    Dependency("libpng_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
