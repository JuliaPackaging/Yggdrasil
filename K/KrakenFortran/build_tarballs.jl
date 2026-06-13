using BinaryBuilder, Pkg

name = "KrakenFortran"
version = v"0.1.0"

sources = [
    GitSource("https://github.com/vardister/KrakenFortran.jl.git", "1a3ab37ed8501ff7490f79a6f88c827b2bd02e55")
]

# Bash recipe utilizing CMake for cross-compilation
script = raw"""
cd $WORKSPACE/srcdir
FORTRAN_ROOT=$(find . -name "src_fortran" -type d -print -quit)

if [ -z "$FORTRAN_ROOT" ]; then
    echo "Error: Could not find src_fortran directory."
    exit 1
fi

cd "$FORTRAN_ROOT/source"
mkdir -p build && cd build

# Configure and build using CMake toolchain args provided by BinaryBuilder
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      ..

make -j${nproc}
make install
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct("libkraken", :libkraken)
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
