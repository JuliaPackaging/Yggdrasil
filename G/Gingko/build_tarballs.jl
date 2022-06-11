# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Gingko"
version = v"1.4.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ginkgo-project/ginkgo/archive/refs/tags/v$(version).tar.gz", "6dcadbd3e93f6ec58ef6cda5b980fbf51ea3c7c13e27952ef38804058ac93f08")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ginkgo-*
mkdir build && cd build

cmake .. \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DGINKGO_BUILD_TESTS=OFF \
-DGINKGO_BUILD_EXAMPLES=OFF \
-DGINKGO_BUILD_BENCHMARKS=OFF \
-DGINKGO_BUILD_REFERENCE=OFF \
-DGINKGO_BUILD_DOC=OFF \
-DGINKGO_BUILD_HWLOC=OFF

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
 platforms = expand_cxxstring_abis(supported_platforms(; experimental = true))


# The products that we will ensure are always built
products = [
    LibraryProduct("libginkgo_hip", :libgingko_hip),
    LibraryProduct("libginkgo_dpcpp", :libgingko_dpcpp),
    LibraryProduct("libginkgo_omp", :libgingko_omp),
    LibraryProduct("libginkgo_reference", :libgingko_reference),
    LibraryProduct("libginkgo_cuda", :libgingko_cuda),
    LibraryProduct("libginkgo_device", :libgingko_device),
    LibraryProduct("libginkgo", :libgingko)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[ 
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
#needs at least gcc 5.5 according to README, BB only has 5.2.0
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6.1.0")
