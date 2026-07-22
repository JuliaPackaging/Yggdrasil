# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libinput"
version = v"1.31.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.freedesktop.org/libinput/libinput", "26191d396d74d505541d6311f0b4ae68d791b890"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libinput/
mkdir build
cd build

meson setup -D libwacom=false -D tests=false -D documentation=false -D debug-gui=false ../ --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(Sys.islinux, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libinput", :libinput),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("eudev_jll"),
    Dependency("mtdev_jll"),
    Dependency("libevdev_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
