# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "fts"
version = v"1.2.7"

# Collection of sources required to build fts
sources = [
    ArchiveSource("https://github.com/pullmoll/musl-fts/archive/v$version.zip",
                  "3b1fe92f1d8cb98488d1bce2ad078cd815f10a0fad0c03caf30229c9318f300b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/musl-fts-*/
./bootstrap.sh
CFLAGS="-fPIC" ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# Select Unix platforms
platforms = [p for p in supported_platforms() if Sys.islinux(p) && libc(p) == "musl"]

# The products that we will ensure are always built
products = [
    LibraryProduct("libfts", :libfts),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
