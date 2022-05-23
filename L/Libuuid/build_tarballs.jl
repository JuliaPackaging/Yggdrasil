# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libuuid"
version = v"2.36"

# Collection of sources required to build FriBidi
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v$(version.major).$(version.minor)/util-linux-$(version.major).$(version.minor).tar.xz",
                  "9e4b1c67eb13b9b67feb32ae1dc0d50e08ce9e5d82e1cccd0ee771ad2fa9e0b1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/util-linux-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-all-programs --enable-libuuid
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> !(Sys.iswindows(p) || Sys.isapple(p)), supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libuuid", :libuuid)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
