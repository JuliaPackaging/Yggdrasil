# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "smesh"
version = v"0.1.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/trixi-framework/smesh.git",
              "55ea1baf2722b3507ec1b8628c41067a211c7e56"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/smesh

mkdir build && cd build

cmake .. \
  -DCMAKE_INSTALL_PREFIX=$prefix \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

platforms = expand_gfortran_versions(platforms)

# Since smesh requires Fortran 2018, we can only build for libgfortran5 or newer

filter!(p -> libgfortran_version(p) >= v"5", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("smesh_run", :mesh_run),
    LibraryProduct("libsmesh", :libsmesh),
    LibraryProduct("libsmesh_io", :libsmesh_io),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"10.1.0", julia_compat="1.6")
