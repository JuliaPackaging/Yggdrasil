# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ORC"
version = v"4.31.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gstreamer.freedesktop.org/src/orc/orc-0.4.31.tar.xz", "a0ab5f10a6a9ae7c3a6b4218246564c3bf00d657cbdf587e6d34ec3ef0616075")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd orc-0.4.31
mkdir build && cd build
meson .. --cross-file=${MESON_TARGET_TOOLCHAIN}
ninja
ninja install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liborc-test-0.4", :liborc_test),
    ExecutableProduct("orcc", :orcc),
    LibraryProduct("liborc-0.4", :liborc),
    ExecutableProduct("orc-bugreport", :orc_bugreport)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
