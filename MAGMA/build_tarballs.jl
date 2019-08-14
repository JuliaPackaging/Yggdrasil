using BinaryBuilder

# Collection of sources required to build Nettle
name = "MAGMA"
version = v"2.5.1"
sources = [
    "http://icl.utk.edu/projectsfiles/magma/downloads/magma-2.5.1.tar.gz" =>
    "ce32c199131515336b30c92a907effe0c441ebc5c5bdb255e4b06b2508de109f",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/magma-*/

# We need a newer version of FindCUDA.cmake
curl -L 'https://raw.githubusercontent.com/Kitware/CMake/v3.13.0/Modules/FindCUDA.cmake' -o /usr/share/cmake/Modules/FindCUDA.cmake

# Apply patches to force name-mangling
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fortran_mangling.patch

mkdir build && cd build
export CFLAGS="${CFLAGS} -DMAGMA_ILP64"
cmake .. -DCMAKE_TOOLCHAIN_FILE=/opt/${target}/${target}.toolchain \
    -DLAPACK_LIBRARIES="-lopenblas64_ -lgfortran -lquadmath" \
    -DCUDA_TOOLKIT_ROOT_DIR="${prefix}" \
    -DCUDA_TOOLKIT_TARGET_DIR="${prefix}" \
    -DGPU_TARGET="Maxwell Pascal Volta" \
    -DCUDA_TOOLKIT_ROOT_DIR_INTERNAL="${prefix}"

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64),
    Windows(:x86_64),
    MacOS(:x86_64),
]
platforms = expand_gcc_versions(platforms)

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libMAGMA", :libMAGMA),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/CUDA-v10.1.168%2B2/build_CUDA.v10.1.168.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/OpenBLAS-v0.3.5-1/build_OpenBLAS.v0.3.5.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
