# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Htop"
version = v"3.3.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/htop-dev/htop/releases/download/$(version)/htop-$(version).tar.xz",
                  "a69acf9b42ff592c4861010fce7d8006805f0d6ef0e8ee647a6ee6e59b743d5c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/htop-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    ExecutableProduct("htop", :htop)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Ncurses_jll"; compat="6.4.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # Only with GCC 6+ ${includedir} by default in header search path for musl.
               julia_compat = "1.6", preferred_gcc_version=v"6")

