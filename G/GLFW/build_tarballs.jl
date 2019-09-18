using BinaryBuilder

version = v"3.3"

# Collection of sources required to build glfw
sources = [
    "https://github.com/glfw/glfw.git" =>
    "b0796109629931b6fa6e449c15a177845256a407",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd glfw/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain -DBUILD_SHARED_LIBS=ON -DGLFW_BUILD_EXAMPLES=false -DGLFW_BUILD_TESTS=false
make -j${ncore}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    MacOS(:x86_64),
    Windows(:x86_64),
    Windows(:i686),
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libglfw", :libglfw)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "glfw", version, sources, script, platforms, products, dependencies)
