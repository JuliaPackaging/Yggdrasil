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
cmake -DGINKGO_BUILD_TESTS=OFF -DGINKGO_BUILD_BENCHMARKS=ON -DGINKGO_BUILD_EXAMPLES=ON -DGINKGO_DOC_GENERATE_EXAMPLES=OFF -G "Ninja" ../
ninja -j${nproc} 
DESTDIR=${WORKSPACE}/destdir/shared ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libginkgo", :libginkgo, "shared/usr/local/lib"),
    LibraryProduct("libginkgo_device", :libginkgo_device, "shared/usr/local/lib"),
    LibraryProduct("libginkgo_cuda", :libginkgo_cuda, "shared/usr/local/lib"),
    LibraryProduct("libginkgo_reference", :libginkgo_reference, "shared/usr/local/lib"),
    LibraryProduct("libginkgo_omp", :libginkgo_omp, "shared/usr/local/lib"),
    LibraryProduct("libginkgo_dpcpp", :libginkgo_dpcpp, "shared/usr/local/lib"),
    LibraryProduct("libginkgo_hip", :libginkgo_hip, "shared/usr/local/lib")
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"12.1.0")
