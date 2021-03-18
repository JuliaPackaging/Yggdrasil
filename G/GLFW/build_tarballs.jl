using BinaryBuilder

name = "GLFW"
version = v"3.3.3"

# Collection of sources required to build glfw
sources = [
    ArchiveSource("https://github.com/glfw/glfw/releases/download/$(version)/glfw-$(version).zip",
    "723087ad45b40cd333be7d1a2cd5e09a28facb7f3acdb69f3e5613bd20543977")
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
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Libglvnd_jll"),
    Dependency("Xorg_libXcursor_jll"),
    Dependency("Xorg_libXi_jll"),
    Dependency("Xorg_libXinerama_jll"),
    Dependency("Xorg_libXrandr_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
