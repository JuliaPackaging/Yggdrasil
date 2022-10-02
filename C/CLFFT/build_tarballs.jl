# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CLFFT"
version = v"2.12.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/clMathLibraries/clFFT.git", "1e4833f060976971c4df4b54b1b9ad1620aaf1fb")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

install_license ./clFFT/LICENSE

cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -S ./clFFT/src -B ./clFFT/build
cmake --build ./clFFT/build --target install -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libclFFT", :libclfft)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="OpenCL_Headers_jll", version=v"2022.09.23")),
    BuildDependency(PackageSpec(; name="OpenCL_jll", version=v"2022.09.23")),
    BuildDependency(PackageSpec(name="FFTW_jll", version=v"3.3.10")),
    BuildDependency(PackageSpec(name="boost_jll", version=v"1.76.0"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6.1.0")
