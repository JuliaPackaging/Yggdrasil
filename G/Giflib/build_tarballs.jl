# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Giflib"
version = v"5.2.1"

# Collection of sources required to build Giflib
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/giflib/giflib-$(version).tar.gz",
                  "31da5562f44c5f15d63340a09a4fd62b48c45620cd302f77a6d9acf0077879bd"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/giflib-*/
make -j${nproc}
make install PREFIX="${prefix}" LIBDIR="${libdir}"
rm "${libdir}/libgif.a"
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgif", :libgif),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
