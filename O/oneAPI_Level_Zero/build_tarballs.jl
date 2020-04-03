# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "oneAPI_Level_Zero"
version = v"0.91.10"

# Collection of sources required to build this package
sources = [
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "ebb363e938a279cf866cb93d28e31aaf0791ea19")
]

# Bash recipe for building across all platforms
script = raw"""
cd level-zero
install_license LICENSE

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc)
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libze_loader", :libze_loader),
    LibraryProduct("libze_validation_layer", :libze_validation_layer),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("OpenCL_Headers_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"5")
