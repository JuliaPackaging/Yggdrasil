# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Qhull"
version = v"2019.1"

# Collection of sources required to build
sources = [
    GitSource(
        "https://github.com/qhull/qhull",           # project URL
        "b94cff0799f36068dee5d800d5cef3b9b911c400"  # commit hash corresponding to the version
    ),
]

# Bash recipe for building across all platforms
script = raw"""
# initial setup
ls $WORKSPACE/srcdir/
ls $WORKSPACE/srcdir/qhull-*
cd $WORKSPACE/srcdir/qhull

# begin the build process
cd build

# Generate makefiles
cmake -G "Unix Makefiles" .. && cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..

# Ensure the config is correct
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..

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
