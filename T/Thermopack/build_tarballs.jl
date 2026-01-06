using BinaryBuilder

name = "thermopack"
version = v"2.2.4"  # Update to the desired version

# Collection of sources required to build thermopack
sources = [
    GitSource("https://github.com/thermotools/thermopack.git", 
              "v2.2.4")  # Update tag/commit as needed
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/thermopack

# Create build directory
mkdir build
cd build

# Configure with CMake
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON

# Build
make -j${nproc}

# Install
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Filter out platforms that don't support Fortran
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libthermopack", :libthermopack),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS_jll"),  # Provides BLAS and LAPACK
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)