# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Kokkos"
version_string = "3.7.02"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kokkos/kokkos.git",
	      "1a0c2ff6daf1068c65529ec04c2c046177847869"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/kokkos

OPENMP_FLAG=()

mkdir build
cd build/

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_CXX_STANDARD=17 \
    -DKokkos_ENABLE_OPENMP=ON

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
#Kokkos assumes a 64-bit build, remove 32-bit platforms
filter!(p -> nbits(p) != 32, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libkokkoscore", :libkokkoscore),
    LibraryProduct("libkokkoscontainers", :libkokkoscontainers),
    LibraryProduct("libkokkossimd", :libkokkossimd)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
#minimum supported gcc on x86_64 is 5.3.0, BB only has 5.2.0 so we bump up to 6
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7")
