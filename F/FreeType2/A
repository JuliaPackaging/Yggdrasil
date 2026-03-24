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
    --prefix=${prefix}
    --build=${MACHTYPE}
    --host=${target}
    --enable-shared
    --disable-static
    --with-brotli=no
    --with-bzip2=yes
    --with-harfbuzz=no   # do not set this to `auto` -- this could load a system library which can be disastrous when the versions don't match
    --with-librsvg=no
    --with-png=no
    --with-zlib=yes
)
./configure ${flags[@]}
make -j${nproc}
make install
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
