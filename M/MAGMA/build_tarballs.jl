using BinaryBuilder

# Collection of sources required to build Nettle
name = "MAGMA"
version = v"2.6.1"
sources = [
    ArchiveSource("http://icl.utk.edu/projectsfiles/magma/downloads/magma-2.6.1.tar.gz", 
    "6cd83808c6e8bc7a44028e05112b3ab4e579bcc73202ed14733f66661127e213")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/magma-*/
curl -L 'https://raw.githubusercontent.com/Kitware/CMake/v3.13.0/Modules/FindCUDA.cmake' -o /usr/share/cmake/Modules/FindCUDA.cmake

mkdir build && cd build
export CFLAGS="${CFLAGS} -DMAGMA_ILP64"
CMAKE_POLICY_DEFAULT_CMP0021=OLD \
CUDA_BIN_PATH=${prefix}/cuda/bin \
CUDA_LIB_PATH=${prefix}/cuda/lib64 \
CUDA_INC_PATH=${prefix}/cuda/include \
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCUDA_TOOLKIT_ROOT_DIR="${prefix}/cuda" \
    -DCUDA_TOOLKIT_TARGET_DIR="${prefix}/cuda" \
    -DBUILD_SHARED_LIBS=on \
    -DGPU_TARGET="Maxel Pascal Volta Turing Ampere"

make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built 
products = [
    LibraryProduct("libMAGMA", :libMAGMA),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("CUDA_full_jll"),
    Dependency("libblastrampoline_jll"),
    Dependency("CUDA_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
