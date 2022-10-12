# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "protozero"
version = v"1.7.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mapbox/protozero.git", "f379578a3f7c8162aac0ac31c2696de09a5b5f93")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/protozero

mkdir build && cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
# protozero is a header only library, so no binary products
products = [
    FileProduct("include/protozero/pbf_writer.hpp", :pbf_writer),
    FileProduct("include/protozero/pbf_reader.hpp", :pbf_reader),
    FileProduct("include/protozero/pbf_message.hpp", :pbf_message),
    FileProduct("include/protozero/pbf_builder.hpp", :pbf_builder),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")
