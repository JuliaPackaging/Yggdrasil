# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LAMMPS"
version = v"20201029.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lammps/lammps.git", "88fd96ec52f86dba4b222623f3a06632a32e42f1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lammps/
mkdir build
cd build/
cmake ../cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DLAMMPS_EXCEPTIONS=ON -DPKG_SNAP=ON
make -j
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("liblammps", :liblammps),
    ExecutableProduct("lmp", :lmp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
