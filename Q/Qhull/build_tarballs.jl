# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Qhull"
version = v"2019.1"

# Collection of sources required to build
sources = [
    ArchiveSource(
        "https://github.com/qhull/qhull/archive/$(version.major).$(version.minor).tar.gz", # URL
        "cf7235b76244595a86b9407b906e3259502b744528318f2178155e5899d6cf9f"                 # sha256 hash
    ),
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
    
    # Files
    # Reentrant Qhull header files
    FileProduct("geom_r.h", :geom_r; dir_path = "libqhull_r"),
    FileProduct("io_r.h", :io_r; dir_path = "libqhull_r"),
    FileProduct("libqhull_r.h", :libqhull_r; dir_path = "libqhull_r"),
    FileProduct("mem_r.h", :mem_r; dir_path = "libqhull_r"),
    FileProduct("merge_r.h", :merge_r; dir_path = "libqhull_r"),
    FileProduct("poly_r.h", :poly_r; dir_path = "libqhull_r"),
    FileProduct("qhull_ra.h", :qhull_ra; dir_path = "libqhull_r"),
    FileProduct("qset_r.h", :qset_r; dir_path = "libqhull_r"),
    FileProduct("random_r.h", :random_r; dir_path = "libqhull_r"),
    FileProduct("stat_r.h", :stat_r; dir_path = "libqhull_r"),
    FileProduct("user_r.h", :user_r; dir_path = "libqhull_r"),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
