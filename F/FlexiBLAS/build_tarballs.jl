using BinaryBuilder

name = "FlexiBLAS"
version = v"3.0.4"

# Collection of sources required to build Sundials
sources = [
    GitSource("https://github.com/mpimd-csc/flexiblas",
              "fae1b3c4d546ddae73b369570ff6fecd8127fcbf"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/flexiblas*

# Build
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    ..
make -j${nproc}
make install
"""

# We attempt to build for all defined platforms
platforms = supported_platforms()
#platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct("libflexiblas", :libflexiblas),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"6")
