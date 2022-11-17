# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "XZ"
version = v"5.2.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://tukaani.org/xz/xz-$(version).tar.xz",
                  "8712e9acb0b6b49a97d443458a3067dc5c08a025e02dc5f773176c51dd7cfc69"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xz-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-pic
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("xzdec", :xzdec),
    ExecutableProduct("lzmainfo", :lzmainfo),
    ExecutableProduct("xz", :xz),
    LibraryProduct("liblzma", :liblzma),
    ExecutableProduct("lzmadec", :lzmadec),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

