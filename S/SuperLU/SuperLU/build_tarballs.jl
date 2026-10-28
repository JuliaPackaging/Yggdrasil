# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SuperLU"
version = v"7.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xiaoyeli/superlu.git", "83a3c82b9e44c966ca2bc26991ffdb2bf63e1e2b"; tag="v$(version)"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/superlu
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -Denable_internal_blaslib=OFF \
    -Denable_examples=OFF \
    -Denable_tests=OFF \
    -DTPL_BLAS_LIBRARIES="${libdir}/libopenblas.${dlext}"
cmake --build build --parallel ${nproc}
cmake --install build
install_license License.txt
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
    # 0.3.29 is the first version built for riscv64 and FreeBSD aarch64.
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"); compat="0.3.29"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.11", preferred_gcc_version=v"8")
