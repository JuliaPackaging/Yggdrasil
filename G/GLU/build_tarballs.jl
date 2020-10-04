# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GLU"
version = v"9.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://salsa.debian.org/xorg-team/lib/libglu.git", "d77f0cae59ce18bc7bba7b1f0c0b605224c23783")
]

# Bash recipe for building across all platforms
script = raw"""
cd libglu
./autogen.sh --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j ${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libGLU", :libGLU)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
