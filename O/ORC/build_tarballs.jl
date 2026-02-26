# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ORC"
# Our ORC version numbers are off, this is actually 0.4.42
version = v"4.42.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gstreamer.freedesktop.org/src/orc/orc-0.$(version.major).$(version.minor).tar.xz",
                  "7ec912ab59af3cc97874c456a56a8ae1eec520c385ec447e8a102b2bd122c90c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/orc*
meson setup build --buildtype=release --cross-file=${MESON_TARGET_TOOLCHAIN}
meson compile -C build -j ${nproc}
meson install -C build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["liborc-test-0.4", "liborc-test-0"], :liborc_test),
    ExecutableProduct("orcc", :orcc),
    LibraryProduct(["liborc-0.4", "liborc-0"], :liborc),
    ExecutableProduct("orc-bugreport", :orc_bugreport)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"5")
