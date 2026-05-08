# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "grok"
version = v"20.3.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/GrokImageCompression/grok/releases/download/v$(version)/source-full.tar.gz",
                  "e51302338564648bcd966429bb5bea9d48e3a3958820df77bf691f7d678aa810"),
    # FileSource("https://github.com/joseluisq/MacOSX-SDKs/releases/download/15.0/MacOSX15.0.sdk.tar.xz",
    #            "9df0293776fdc8a2060281faef929bf2fe1874c1f9368993e7a4ef87b1207f98"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/grok*

# if [[ "${target}" == *-apple-darwin* ]]; then 
#     # Install a newer SDK which supports C++23 
# 
#     # apple_sdk_root=$WORKSPACE/srcdir/MacOSX15.0.sdk 
#     # sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN 
#     # sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++ 
# 
#     rm -rf /opt/${target}/${target}/sys-root/System
#     rm -rf /opt/${target}/${target}/sys-root/usr/include/libxml2/libxml
#     # extract the tarball into the sys-root so all compilers pick it up
#     # automatically, and use --warning=no-unknown-keyword to hide harmless
#     # warnings about unsupported pax header keywords like "SCHILY.fflags"
#     tar --extract \
#         --file=${WORKSPACE}/srcdir/MacOSX15.0.sdk.tar.xz \
#         --directory="/opt/${target}/${target}/sys-root/." \
#         --strip-components=1 \
#         --warning=no-unknown-keyword \
#         MacOSX15.0.sdk/System
#     tar --extract \
#         --file=${WORKSPACE}/srcdir/MacOSX15.0.sdk.tar.xz \
#         --directory="/opt/${target}/${target}/sys-root/." \
#         --strip-components=1 \
#         --warning=no-unknown-keyword \
#         MacOSX15.0.sdk/usr
# 
#     export MACOSX_DEPLOYMENT_TARGET=15.0 
# fi 

# Use our own, newer cmake
apk del cmake

atomic_patch -p1  ${WORKSPACE}/srcdir/patches/cinttypes.patch

# Use proper C++ include headers
find examples -type f \( -name '*.h' -o -name '*.cpp' \) -exec sed -i 's/#include <inttypes\.h>/#include <cinttypes>/g' {} +

# Correct case of file name
find src -type f \( -name '*.h' -o -name '*.cpp' \) -exec sed -i 's/#include <Windows\.h>/#include <windows.h>/g' {} +

# Fix namespace location of `aligned_alloc` on Apple
if [[ ${target} == *-apple-* ]]; then
    find src -type f \( -name '*.h' -o -name '*.cpp' \) -exec sed -i 's/std::aligned_alloc/::aligned_alloc/g' {} +
fi

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

install_license LICENSE
"""

sources, script = require_macos_sdk("15.0", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# grok uses `malloc_trim`, which is not available in musl
# (We could provide a trivial implementation if we wanted.)
filter!(p -> libc(p) != "musl", platforms)

# Windows is not supported. The cmake file uses ELF options and probably has never heard of Windows.
filter!(!Sys.iswindows, platforms)

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
