# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))
# Note: Different minor versions of `OpenEXR_jll` are not ABI compatible.
# All downstream packages know this and use explicit compat bounds.

name = "OpenColorIO"
version = v"2.6.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AcademySoftwareFoundation/OpenColorIO", "10a43ec1df03d072ca9a9e2fb3f26e454b0900d8";
              tag="v$(version)"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/OpenColorIO*

if [[ ${target} == *mingw* ]]; then
   # Our mingw is too old and doesn't know how to create an `ifstream` from a `wstring`
   atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw.patch
fi

args=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DOCIO_BUILD_GPU_TESTS=OFF
    -DOCIO_BUILD_PYTHON=OFF
    -DOCIO_BUILD_TESTS=OFF
    -DOCIO_DIRECTX_ENABLED=OFF
    -DOCIO_USE_HEADLESS=ON
)
if [[ ${target} == *darwin* ]]; then
   # On Darwin, cmake picks `llvm-strip` which doesn't understand the Mach-O format.
   args+=(-DCMAKE_STRIP=${target}-strip)
fi
cmake -B build -G Ninja "${args[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE
"""

sources, script = require_macos_sdk("11.0", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("ocioarchive"     , :ocioarchive     ),
    ExecutableProduct("ociobakelut"     , :ociobakelut     ),
    ExecutableProduct("ociocheck"       , :ociocheck       ),
    ExecutableProduct("ociochecklut"    , :ociochecklut    ),
    ExecutableProduct("ociocpuinfo"     , :ociocpuinfo     ),
    ExecutableProduct("ociomakeclf"     , :ociomakeclf     ),
    ExecutableProduct("ocioperf"        , :ocioperf        ),
    ExecutableProduct("ociomergeconfigs", :ociomergeconfigs),
    ExecutableProduct("ociowrite"       , :ociowrite       ),
    ExecutableProduct("ociolutimage"    , :ociolutimage    ),
    ExecutableProduct("ocioconvert"     , :ocioconvert     ),
    LibraryProduct(["libOpenColorIO", "libOpenColorIO_2_6"], :libOpenColorIO),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # minizip-ng
    Dependency("Expat_jll"; compat="2.8.4"),
    Dependency("Imath_jll"; compat="~3.2.2"),
    Dependency("OpenEXR_jll"; compat="~3.5.2"),
    Dependency("Zlib_jll"),
    Dependency("yaml_cpp_jll"; compat="0.9.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
