# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "FreeType2"
version = v"2.13.2"

# Collection of sources required to build FreeType2
sources = [
    ArchiveSource("https://download.savannah.gnu.org/releases/freetype/freetype-$(version).tar.xz",
                  "12991c4e55c506dd7f9b765933e62fd2be2e06d421505d7950a132e4f1bb484d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/freetype-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared --disable-static
make -j${nproc}
make install
install_license docs/{FTL,GPLv2}.TXT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfreetype", :libfreetype),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
