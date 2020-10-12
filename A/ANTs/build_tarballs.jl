# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ANTs"
version = v"2.3.4"

# Collection of sources required to complete build
sources = [
    GitSource("git://github.com/stnava/ANTs.git", "857b744cc6eeb72d5cd388933a3492846274cfdf")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir antsbin
cd antsbin
cmake ../ANTs -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)