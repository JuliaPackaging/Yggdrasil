# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mujoco_core"
version = v"2.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://mujoco.org/download/mujoco210-linux-x86_64.tar.gz", "a436ca2f4144c38b837205635bbd60ffe1162d5b44c87df22232795978d7d012")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cp mujoco210/bin/*.so ${prefix}
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libmujoco210nogl", :libmujoco210nogl),
    LibraryProduct("libmujoco210", :libmujoco210),
    LibraryProduct("libglewegl", :libglewegl),
    LibraryProduct("libglewosmesa", :libglewosmesa),
    LibraryProduct("libglew", :libglew)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
