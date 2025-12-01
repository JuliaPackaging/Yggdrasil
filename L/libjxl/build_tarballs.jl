# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "libjxl"
version = v"0.11.1"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/libjxl/libjxl.git",
        "794a5dcf0d54f9f0b20d288a12e87afb91d20dfc"),
]

# TODO: brotli and highway are dependencies. I think by default this builds them as shared libraries.
# brotli is already a JLL so we should probably depend on that instead and ask to use the system one.
# for highway, maybe we can distribute the shared lib here, or get it to bake in statically(?)
script = raw"""
cd $WORKSPACE/srcdir/libjxl/
# download dependencies
$WORKSPACE/srcdir/libjxl/deps.sh
mkdir build
cd build

cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTING=OFF \
   ..

cmake --build . -- -j$(nproc)
cmake --install .
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libjxl", :libjxl),
    ExecutableProduct("cjxl", :cjxl),
    ExecutableProduct("djxl", :djxl),
    ExecutableProduct("jxltran", :jxltran),
    ExecutableProduct("jxlinfo", :jxlinfo),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c], lock_microarchitecture=false)
