# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ginkgo"
version = v"1.6.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/youwuyou/ginkgo.git", "c4128a21b1114bedfc19153a9508b2bd3b54954f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ginkgo/
mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DGINKGO_BUILD_TESTS=OFF \
    -DGINKGO_BUILD_BENCHMARKS=OFF \
    -DGINKGO_BUILD_EXAMPLES=OFF \
    -DGINKGO_DOC_GENERATE_EXAMPLES=OFF \
    -DGINKGO_BUILD_REFERENCE=ON \
    -DGINKGO_BUILD_OMP=ON \
    -DGINKGO_BUILD_CUDA=OFF \
    -DGINKGO_BUILD_HIP=OFF \
    -DGINKGO_BUILD_SYCL=OFF \
    -DGINKGO_BUILD_HWLOC=OFF \
    -DGINKGO_BUILD_MPI=OFF \
    -G "Ninja" ../
ninja -j${nproc} 
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(filter!(Sys.islinux, supported_platforms()))

# The products that we will ensure are always built
products = [
    LibraryProduct("libginkgo", :libginkgo),
    LibraryProduct("libginkgo_device", :libginkgo_device),
    LibraryProduct("libginkgo_cuda", :libginkgo_cuda),
    LibraryProduct("libginkgo_reference", :libginkgo_reference),
    LibraryProduct("libginkgo_omp", :libginkgo_omp),
    LibraryProduct("libginkgo_dpcpp", :libginkgo_dpcpp),
    LibraryProduct("libginkgo_hip", :libginkgo_hip)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
