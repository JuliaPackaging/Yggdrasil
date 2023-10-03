# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "obstack"
version = v"1.2.3"

# Collection of sources required to build obstack
sources = [
    GitSource("https://github.com/void-linux/musl-obstack.git",
              "f4385255be1615688c6a5f042277304d7ab288b1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/musl-obstack/
./bootstrap.sh
CFLAGS="-fPIC" ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(Sys.islinux, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libobstack", :libobstack),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
