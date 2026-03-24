# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "FreeType2"
version = v"2.14.3"

# Collection of sources required to build FreeType2
sources = [
    ArchiveSource("https://download.savannah.gnu.org/releases/freetype/freetype-$(version).tar.xz",
                  "36bc4f1cc413335368ee656c42afca65c5a3987e8768cc28cf11ba775e785a5f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/freetype-*
flags=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DBUILD_SHARED_LIBS=ON
    -DFT_DISABLE_BROTLI=ON
    -DFT_DISABLE_HARFBUZZ=ON
    -DFT_DISABLE_PNG=ON
    -DFT_REQUIRE_BZIP2=ON
    -DFT_REQUIRE_ZLIB=ON
    -DFT_DYNAMIC_HARFBUZZ=OFF   # leave this off -- this could load a system library which can be disastrous when the versions don't match
)
cmake -Bbuild ${flags[@]}
cmake --build build --parallel ${nproc}
cmake --install build
install_license docs/{FTL,GPLv2}.TXT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libfreetype", :libfreetype),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
