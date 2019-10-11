using BinaryBuilder

version = v"3.3"
major, minor, patch = version.major, version.minor, version.patch
# Collection of sources required to build glfw
sources = [
    "https://github.com/glfw/glfw/archive/$major.$minor.tar.gz" =>
    "81bf5fde487676a8af55cb317830703086bb534c53968d71936e7b48ee5a0f3e"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd glfw*/

BUILD_FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=ON
    -DGLFW_BUILD_EXAMPLES=OFF
    -DGLFW_BUILD_DOCS=OFF
    -DGLFW_BUILD_TESTS=OFF
    "-DCMAKE_INSTALL_PREFIX=${prefix}"
    "-DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}""
)

mkdir build
cd build
cmake .. "${BUILD_FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc),
    Linux(:x86_64, libc=:musl),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libglfw", :libglfw)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Libglvnd_jll",
    "X11_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "glfw", version, sources, script, platforms, products, dependencies)
