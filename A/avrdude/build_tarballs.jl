# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "avrdude"
version = v"7.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/avrdudes/avrdude.git", "2e0be1e1aedfc10c904712bddda37e36356e7a66")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/avrdude/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=!Sys.islinux)


# The products that we will ensure are always built
products = [
    ExecutableProduct("avrdude", :avrdude)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libusb_jll", uuid="a877fdc9-fe69-5ed6-b93d-11ecd0dc2d49"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
