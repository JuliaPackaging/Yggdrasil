# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CubicInterpolation"
version = v"0.1.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tudo-astroparticlephysics/cubic_interpolation.git",
              "2ac2899d9f3457b595299b3762934bc10ad984bf"),  # v0.1.5
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cubic_interpolation*
mkdir -p build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF \
    -DBUILD_EXAMPLE=OFF
make -j${nproc}
make install
install_license $WORKSPACE/srcdir/cubic_interpolation*/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# Filter out platforms with build issues
# Windows: linking issues with shared library exports
# RISC-V: not yet supported
filter!(p -> !Sys.iswindows(p), platforms)
filter!(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libCubicInterpolation", :libCubicInterpolation),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"; compat="=1.79.0"),
    BuildDependency("Eigen_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
