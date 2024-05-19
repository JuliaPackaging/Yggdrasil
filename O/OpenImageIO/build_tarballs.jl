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
    Dependency("FFMPEG_jll"; compat="6.1.1"),
    Dependency("FreeType2_jll"; compat="2.13.1"),
    Dependency("Giflib_jll"; compat="5.2.1"),
    Dependency("JpegTurbo_jll"; compat="3.0.1"),
    Dependency("Libtiff_jll"; compat="4.5.1"),
    Dependency("OpenEXR_jll"; compat="~3.2.4"),
    Dependency("OpenJpeg_jll"; compat="2.5.0"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("boost_jll"; compat="=1.76.0"),
    Dependency("libpng_jll"; compat="1.6.38"),
    Dependency("libwebp_jll"; compat="1.2.4"),
    Dependency("pugixml_jll"; compat="1.11.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
