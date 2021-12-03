# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Usrsctp"
version = v"0.9.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sctplab/usrsctp.git", "07f871bda23943c43c9e74cc54f25130459de830")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/usrsctp/
mkdir build && cd build
meson --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libusrsctp", :libusrsctp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
