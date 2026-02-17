# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "OpenImageIO"
version = v"3.1.8"              # This is 3.1.8.0

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AcademySoftwareFoundation/OpenImageIO", "63098ef0652e739ff4397df89974f91991d62c19"),
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
install_license LICENSE.md RELICENSING.md
"""

sources, script = require_macos_sdk("11.0", sources, script)

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
    Dependency("FFMPEG_jll"; compat="8.0.1"),
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("Giflib_jll"; compat="5.2.3"),
    Dependency("JpegTurbo_jll"; compat="3.1.4"),
    Dependency("Libtiff_jll"; compat="4.7.2"),
    Dependency("OpenColorIO_jll"; compat="2.5.0"),
    Dependency("OpenEXR_jll"; compat="~3.4.4"),
    Dependency("OpenJpeg_jll"; compat="2.5.4"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("boost_jll"; compat="=1.87.0"),
    Dependency("libpng_jll"; compat="1.6.53"),
    Dependency("libwebp_jll"; compat="1.6.0"),
    Dependency("pugixml_jll"; compat="1.15.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
