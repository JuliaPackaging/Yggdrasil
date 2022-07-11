# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MParT"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/MeasureTransport/MParT.git", "64e4b8ee7637382ab7f9aa091ace41ed6a5cbcc6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir MParT/build && cd MParT/build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DCMAKE_BUILD_TYPE=Release \
  -DMPART_BUILD_TESTS=OFF \
  -DMPART_PYTHON=OFF ..
make -j${nprocs} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> Sys.isunix(p) && nbits(p) == 64, supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libmpart", :libmpart)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Kokkos_jll", uuid="c1216c3d-6bb3-5a2b-bbbf-529b35eba709"); compat="=3.6.0")
    Dependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")

