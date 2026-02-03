# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PROPOSAL"
version = v"7.6.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tudo-astroparticlephysics/PROPOSAL.git",
              "0d7fb45b2305bd275e90c6d68c1168301198e451"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/PROPOSAL*
mkdir -p build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_PYTHON=OFF \
    -DBUILD_TESTING=OFF \
    -DBUILD_DOCUMENTATION=OFF \
    -DBUILD_EXAMPLE=OFF
make -j${nproc}
make install
install_license $WORKSPACE/srcdir/PROPOSAL*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# Filter out platforms not supported by CubicInterpolation_jll
# Windows: linking issues with shared library exports
# RISC-V: not yet supported
filter!(p -> !Sys.iswindows(p), platforms)
filter!(p -> arch(p) != "riscv64", platforms)
filter!(p -> arch(p) != "armv6l", platforms)
filter!(p -> arch(p) != "armv7l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libPROPOSAL", :libPROPOSAL),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CubicInterpolation_jll"; compat="0.1.5"),
    Dependency("boost_jll"; compat="=1.79.0"),
    BuildDependency("Eigen_jll"),
    Dependency("spdlog_jll"),
    BuildDependency("nlohmann_json_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
