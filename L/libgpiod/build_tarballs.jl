# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libgpiod"
version = v"2.2.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/software/libs/libgpiod/libgpiod-$(version).tar.xz",
                  "0e948049c309b87c220fb24ee0d605d7cd5b72f22376e608470903fffa2d4b18")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgpiod-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("armv7l", "linux", libc="glibc"),
    Platform("aarch64", "linux", libc="glibc"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libgpiod", :libgpiod)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
