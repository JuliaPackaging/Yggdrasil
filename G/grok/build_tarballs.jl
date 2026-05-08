# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "grok"
version = v"20.3.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/GrokImageCompression/grok/releases/download/v$(version)/source-full.tar.gz",
                  "e51302338564648bcd966429bb5bea9d48e3a3958820df77bf691f7d678aa810"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/grok*

# Use our own, newer cmake
apk del cmake

cmake_flags=(
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DBUILD_SHARED_LIBS=ON
    -DGRK_BUILD_JPEG=OFF
    -DGRK_BUILD_LCMS2=OFF
    -DGRK_BUILD_LIBPNG=OFF
    -DGRK_BUILD_LIBTIFF=OFF
    -DSPDLOG_FMT_EXTERNAL=ON
)

if [[ ${target} == aarch64-* ]]; then
    # We are building with old kernel headers that do not define `HWCAP_SVE2`
    cmake_flags+=(-DCMAKE_CXX_FLAGS='-DHWCAP2_SVE2=2')
fi

cmake -Bbuild "${cmake_flags[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgrokj2k", :libgrokj2k),
    LibraryProduct("libgrokj2kcodec", :libgrokj2kcodec),
    ExecutableProduct("grk_compress", :grk_compress),
    ExecutableProduct("grk_decompress", :grk_decompress),
    ExecutableProduct("grk_dump", :grk_dump),
    ExecutableProduct("grk_transcode", :grk_transcode),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("CMake_jll"),
    Dependency("Fmt_jll"; compat="11.1.1"),
    Dependency("JpegTurbo_jll"; compat="3.1.5"),
    Dependency("Libtiff_jll"; compat="4.7.2"),
    Dependency("LittleCMS_jll"; compat="2.19.0"),
    Dependency("Zlib_jll"),
    Dependency("libpng_jll"; compat="1.6.58"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"11")
