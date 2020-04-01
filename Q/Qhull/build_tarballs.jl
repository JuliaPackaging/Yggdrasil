# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Qhull"
version = v"2019.1"

# Collection of sources required to build
sources = [
    "https://github.com/qhull/qhull/archive/$(version.major).$(version.minor).tar.gz" =>
    "cf7235b76244595a86b9407b906e3259502b744528318f2178155e5899d6cf9f",
]

# Bash recipe for building across all platforms
script = raw"""
# initial setup
cd $WORKSPACE/srcdir/qhull*/

# begin the build process
cd build

CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release"

# Generate makefiles
cmake $CMAKE_ARGS -G "Unix Makefiles" .. && cmake $CMAKE_ARGS ..

# Run the build script
make -j${nproc}

# Install Qhull
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("qhull", :qhull),
    ExecutableProduct("rbox", :rbox),
    ExecutableProduct("qconvex", :qconvex),
    ExecutableProduct("qdelaunay", :qdelaunay),
    ExecutableProduct("qvoronoi", :qvoronoi),
    ExecutableProduct("qhalf", :qhalf),
    LibraryProduct(["libqhull_r", "qhull_r"], :libqhull_r),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
