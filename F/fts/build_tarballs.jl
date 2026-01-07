# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "fts"
version = v"1.2.9"  # XXX: upstream is 1.2.7, but we needed a version bump

# Collection of sources required to build fts
sources = [
    GitSource("https://github.com/void-linux/musl-fts.git",
              "0bde52df588e8969879a2cae51c3a4774ec62472"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/musl-fts/
./bootstrap.sh
CFLAGS="-fPIC" ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license ./COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
filter!(Sys.islinux, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfts", :libfts),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
