# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SuperLU_MT"
version = v"4.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xiaoyeli/superlu_mt.git", "f2e50bfcbb7b20ef304c84cf92c038c283019863"; tag="v$(version)"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/superlu_mt
if [[ ${nbits} == 64 ]]; then
    LONGINT=ON
else
    LONGINT=OFF
fi
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DTHREAD_API=OPENMP \
    -DLONGINT=${LONGINT} \
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
    LibraryProduct("libsuperlu_mt_OPENMP", :libsuperlu_mt_OPENMP),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # 0.3.29 is the first version built for riscv64 and FreeBSD aarch64.
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"); compat="0.3.29"),
    # libgomp on GCC targets, libomp where the toolchain is Clang.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); compat="1.1.1", platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); compat="18.1.7", platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # OpenBLAS32 has only libgfortran5 builds on some platforms (e.g. powerpc64le),
               # and GCC 8 makes the build platform libgfortran5.
               julia_compat="1.11", preferred_gcc_version=v"8")
