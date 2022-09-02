# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "helpme"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/andysim/helpme.git", "00d1e3d3fe54e2b1b2e0df753f3393ed9ac7a19e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/helpme/

mkdir build; cd build

cmake .. -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_MPI=OFF \
    -DENABLE_BLAS=OFF \
    -DENABLE_fortran=OFF \
    -DENABLE_Python=OFF \
    -DBUILD_TESTING=OFF

make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "macos"; ),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "linux"; libc = "glibc")
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libhelpme", :libhelpme)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
