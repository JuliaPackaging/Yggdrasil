# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DirectQhullHelper"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuhaHeiskala/DirectQhullHelper.git", "026813b733ed1926855b1cb0ec3a53e4fa75c207")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/DirectQhullHelper/
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DQHULL_JLL_INCLUDE=${includedir}/libqhull_r ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libDirectQhullHelper", :libDirectQhullHelper)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Qhull_jll", uuid="784f63db-0788-585a-bace-daefebcd302b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
