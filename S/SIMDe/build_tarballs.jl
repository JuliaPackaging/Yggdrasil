# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "SIMDe"
version = v"0.8.2"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/simd-everywhere/simde.git",
        "71fd833d9666141edcd1d3c109a80e228303d8d7",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/simde
install_license COPYING
mkdir build
cd build
meson .. --prefix=${prefix} --libdir=${libdir} --buildtype=release --cross-file=${MESON_TARGET_TOOLCHAIN} -Dtests=false
ninja -j${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line 
platforms = [AnyPlatform()]

# There are no products that are built (header-only library)
products = Product[]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.6",
    preferred_gcc_version = v"9",
)
