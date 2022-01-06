# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "FLAC"
version = v"1.3.3"

# Collection of sources required to build FLAC
sources = [
    ArchiveSource("https://ftp.osuosl.org/pub/xiph/releases/flac/flac-$(version).tar.xz",
                  "213e82bd716c9de6db2f98bcadbc4c24c7e2efe8c75939a1a84e28539c4e1748"),
    DirectorySource("./bundled"),
]

# This version number is falsely incremented to build for experimental platforms
version = v"1.3.4"

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/flac-*/

./configure --prefix=$prefix --host=$target  --build=${MACHTYPE}
make -j${nproc}
make install
install_license COPYING.Xiph
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libFLAC", :libflac),
    LibraryProduct("libFLAC++", :libflacpp),
    ExecutableProduct("metaflac", :metaflac),
    ExecutableProduct("flac", :flac)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Ogg_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

