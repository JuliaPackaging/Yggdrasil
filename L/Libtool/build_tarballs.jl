# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Libtool"
version = v"2.4.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/libtool/libtool-$(version).tar.gz",
                  "e3bd4d5d3d025a36c21dd6af7ea818a2afcd4dfc1ea5a17b39d7854bcd0c06e3")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libtool-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# TODO: in next release include the "experimental" platforms
filter!(p -> !(Sys.isapple(p) && arch(p) == "aarch64") && !(arch(p) == "armv6l"), platforms)

# The products that we will ensure are always built
products = [
    FileProduct("bin/libtool", :libtool),
    FileProduct("bin/libtoolize", :libtoolize),
    LibraryProduct("libltdl", :libltdl),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
