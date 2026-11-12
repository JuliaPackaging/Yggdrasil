# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libevdev"
version = v"1.13.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.freedesktop.org/libevdev/libevdev", "ac0056961c3332a260db063ab4fccc7747638a1d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libevdev/
mkdir build
cd build

meson -D tests=disabled -D documentation=disabled ../ --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(Sys.islinux, supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libevdev", :libevdev),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", julia_compat="1.6")
