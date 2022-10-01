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


# The products that we will ensure are always built
products = [
    LibraryProduct("libclFFT", :libclfft)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenCL_Headers_jll", uuid="a7aa756b-2b7f-562a-9e9d-e94076c5c8ee"))
    Dependency(PackageSpec(name="OpenCL_jll", uuid="6cb37087-e8b6-5417-8430-1f242f1e46e4"))
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6.1.0")
