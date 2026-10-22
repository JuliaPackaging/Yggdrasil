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
# switched to using brotli_jll
# for highway, maybe we can distribute the shared lib here, or get it to bake in statically(?)
script = raw"""
cd $WORKSPACE/srcdir/libjxl/
# download dependencies
$WORKSPACE/srcdir/libjxl/deps.sh
mkdir build
cd build

cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DJPEGXL_FORCE_SYSTEM_BROTLI=ON ..
cmake --build . -- -j$(nproc)
cmake --install .
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = supported_platforms()
# let's not waste CI until we get two platforms working
platforms = [Platform("x86_64", "linux"), Platform("aarch64", "macos")]

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
    Dependency("brotli_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c], lock_microarchitecture=false,
               # SIMD instructions in highway + `-Wimplicit-fallthrough`
               preferred_gcc_version=v"9")
