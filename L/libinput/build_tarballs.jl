# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libinput"
version = v"1.28.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.freedesktop.org/libinput/libinput", "4f7b4ef0e4eb5d569df36be387579858eba349bb"),
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
