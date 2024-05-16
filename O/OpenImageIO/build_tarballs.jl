# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "OpenImageIO"
version = v"2.5.11"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AcademySoftwareFoundation/OpenImageIO", "7141852ffe2186438a1759919b073cad49da642e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/OpenImageIO

cmake -B build-dir -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DOIIO_BUILD_TESTS=0 \
    -DUSE_EXTERNAL_PUGIXML=1 \
    -DUSE_PYTHON=0
cmake --build build-dir --parallel ${nproc}
cmake --install build-dir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("iconvert", :iconvert),
    ExecutableProduct("idiff", :idiff),
    ExecutableProduct("igrep", :igrep),
    ExecutableProduct("iinfo", :iinfo),
    ExecutableProduct("maketx", :maketx),
    ExecutableProduct("oiiotool", :oiiotool),
    ExecutableProduct("testtex", :testtex),
    LibraryProduct("libOpenImageIO", :libOpenImageIO),
    LibraryProduct("libOpenImageIO_Util", :libOpenImageIO_Util),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("FFMPEG_jll"),
    Dependency("FreeType2_jll"),
    Dependency("Giflib_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("Libtiff_jll"),
    Dependency("OpenEXR_jll"),
    Dependency("OpenJpeg_jll"),
    Dependency("Zlib_jll"),
    Dependency("boost_jll"),
    Dependency("libpng_jll"),
    Dependency("libwebp_jll"),
    Dependency("pugixml_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
