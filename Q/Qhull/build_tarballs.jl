# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Qhull"
version = v"8.0.1003" # alpha-3 release of 8.1, but Julia Pkg doesn't support prerelease versions

# Collection of sources required to build
sources = [
    GitSource("https://github.com/qhull/qhull.git",
              "c2ef2209c28dc61ccfd22514971236587e820121"), # v8.1-alpha3 GitHub 2023/01/02
]

# Bash recipe for building across all platforms
script = raw"""
# initial setup
cd $WORKSPACE/srcdir/qhull*/
export CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release"

# begin the build process
cd build

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
    # Executables
    # compute convex hulls and related structures
    ExecutableProduct("qhull", :qhull),
    # generate various point distributions
    ExecutableProduct("rbox", :rbox),
    # compute the convex hull
    ExecutableProduct("qconvex", :qconvex),
    # compute the Delaunay triangulation
    ExecutableProduct("qdelaunay", :qdelaunay),
    # compute the Voronoi diagram
    ExecutableProduct("qvoronoi", :qvoronoi),
    # compute the halfspace intersection about a point
    ExecutableProduct("qhalf", :qhalf),

    # Libraries
    # reentrant Qhull
    LibraryProduct(["libqhull_r", "qhull_r"], :libqhull_r),
    # non-reentrant Qhull is not supported any more
    # LibraryProduct(["libqhull", "qhull"], :libqhull),
    
    # Files
    # Reentrant Qhull header files
    FileProduct("include/libqhull_r/geom_r.h", :geom_r_h),
    FileProduct("include/libqhull_r/io_r.h", :io_r_h),
    FileProduct("include/libqhull_r/libqhull_r.h", :libqhull_r_h),
    FileProduct("include/libqhull_r/mem_r.h", :mem_r_h),
    FileProduct("include/libqhull_r/merge_r.h", :merge_r_h),
    FileProduct("include/libqhull_r/poly_r.h", :poly_r_h),
    FileProduct("include/libqhull_r/qhull_ra.h", :qhull_ra_h),
    FileProduct("include/libqhull_r/qset_r.h", :qset_r_h),
    FileProduct("include/libqhull_r/random_r.h", :random_r_h),
    FileProduct("include/libqhull_r/stat_r.h", :stat_r_h),
    FileProduct("include/libqhull_r/user_r.h", :user_r_h),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Build trigger: 1
