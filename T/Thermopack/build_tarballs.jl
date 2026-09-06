using BinaryBuilder

name = "Thermopack"
version = v"2.2.4"  # Update to the desired version

# Collection of sources required to build thermopack
sources = [
    GitSource("https://github.com/thermotools/thermopack.git", 
              "ca75d8e095e8b951616897efe1bca9b8c3badda7")  # Update tag/commit as needed
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/thermopack

# Patch CMakeLists.txt to remove architecture-specific flags (not allowed by BinaryBuilder)
sed -i 's/-march=x86-64 -msse2//g' CMakeLists.txt
sed -i 's/-arch arm64 -fno-expensive-optimizations//g' CMakeLists.txt
# Remove static libquadmath flag (not supported on all platforms)
sed -i 's/-static-libquadmath//g' src/CMakeLists.txt

# Create build directory
mkdir build
cd build

# Configure with CMake
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DBLAS_LIBRARIES="-L${libdir} -lopenblas" \
      -DLAPACK_LIBRARIES="-L${libdir} -lopenblas" \
      ..

# Build
make -j${nproc}
make install

# Install manually (thermopack's CMake install doesn't respect CMAKE_INSTALL_PREFIX)
cp -v thermopack/libthermopack.${dlext} ${libdir}/
install_license ../LICENSE-MIT ../LICENSE-APACHE
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
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8", julia_compat="1.6")



