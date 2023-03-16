# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Imath"
version = v"3.1.7"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AcademySoftwareFoundation/Imath.git", "a4f9d5c6205482e1f1a86c84bb97bafa247fb774")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Imath*
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DBUILD_TESTING=OFF \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libImath-3_1", :libImath)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0", julia_compat = "1.6")
