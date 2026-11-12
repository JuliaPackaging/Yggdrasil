# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "OpenImageIO"
version_str = "3.2.2.0"
version = let (a, b, c, d) = parse.(Int, split("3.2.2.0", '.'))
    VersionNumber(a, b, 100c + d)
end

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AcademySoftwareFoundation/OpenImageIO", "96377f681cc9e6650c8534671f4fc36b3c8acbc1";
              tag="v$(version_str)"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/OpenImageIO

apk del cmake

cmake_args=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DOIIO_BUILD_TESTS=0
    -DUSE_EXTERNAL_PUGIXML=1
    -DUSE_PYTHON=0
)
if [[ ${target} == i686-linux-musl ]]; then
    # `__stack_chk_fail_local` is not available
    cmake_args+=(-DOIIO_HARDENING=0)
fi

cmake -B build-dir -G Ninja "${cmake_args[@]}"
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
    HostBuildDependency("CMake_jll"),
    Dependency("FFMPEG_jll"; compat="9.0.2"),
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("Giflib_jll"; compat="6.1.3"),
    Dependency("JpegTurbo_jll"; compat="3.2.0"),
    Dependency("Libtiff_jll"; compat="4.7.3"),
    Dependency("OpenColorIO_jll"; compat="~2.6.0"),
    Dependency("OpenEXR_jll"; compat="~3.5.2"),
    Dependency("OpenJpeg_jll"; compat="2.5.5"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("boost_jll"; compat="=1.87.0"),
    Dependency("libpng_jll"; compat="1.6.59"),
    Dependency("libwebp_jll"; compat="1.6.1"),
    Dependency("pugixml_jll"; compat="1.16.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9")
