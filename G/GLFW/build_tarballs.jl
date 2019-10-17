using BinaryBuilder

name = "GLFW"
version = v"3.3"

# Collection of sources required to build glfw
sources = [
    "https://github.com/glfw/glfw/releases/download/$(version.major).$(version.minor)/glfw-$(version.major).$(version.minor).zip" =>
    "36fda4cb173e3eb2928c976b0e9b5014e2e5d12b9b787efa0aa29ffc41c37c4a",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glfw-*/
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DGLFW_BUILD_EXAMPLES=false \
    -DGLFW_BUILD_TESTS=false \
    -DGLFW_BUILD_DOCS=OFF
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libglfw", "glfw3"], :libglfw)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Libglvnd_jll",
    "X11_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
