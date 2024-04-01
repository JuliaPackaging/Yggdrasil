# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Exafmmt"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JoshuaTetzner/exafmm-t.git", "359558a6ae7b82ea936f44a33400fa6ca7e27e52")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/exafmm-t/
mkdir build
cd build
BLAS=blastrampoline
LAPACK=blastrampoline
cmake ../c -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBLAS_LIBRARIES="-l${BLAS}" \
    -DLAPACK_LIBRARIES="-l${LAPACK}" 
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Exafmm-t uses drand48 and srand48 which are both unix only functions, 
# therefore a compilation under windows is not possible.
platforms = [
    Platform("i686", "linux"; libc = "glibc", march="prescott")
    Platform("x86_64", "linux"; libc = "glibc", march="avx")
    Platform("i686", "linux"; libc = "musl", march="prescott")
    Platform("x86_64", "linux"; libc = "musl", march="avx")
    Platform("x86_64", "macOS"; march="avx")
]

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libExafmm64", :libExafmm64)
    LibraryProduct("libExafmm32", :libExafmm32)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms))
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms))
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"); compat="5.1.1")
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.8", preferred_gcc_version = v"12.1.0")
