# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SuperLU"
version = v"5.2.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/xiaoyeli/superlu/archive/v5.2.2.tar.gz", "470334a72ba637578e34057f46948495e601a5988a602604f5576367e606a28c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/superlu*
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -Denable_internal_blaslib=OFF \
    -Denable_matlabmex=OFF \
    -Denable_tests=OFF \
    -Denable_doc=OFF \
    -Denable_single=ON \
    -Denable_double=ON \
    -Denable_complex=ON \
    -Denable_complex16=ON \
    -DTPL_BLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" \
    ..
make -j${nproc}
make install
if [[ "${target}" == *-mingw* ]]; then
    # Manually install the library
    cp "SRC/libsuperlu.${dlext}" "${libdir}/libsuperlu.${dlext}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsuperlu", :libsuperlu)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
