# Note that this script can accept some limited command-line arguments,
# run `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "dtcmp"
version = v"1.1.5"
# We bumped the version number because we updated the compat entries for MPI to build for new architectures
ygg_version = v"1.1.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/LLNL/dtcmp", "bbd720f6db41106380b11610ebb893f3edd47c47"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/dtcmp

export MPITRAMPOLINE_CC="${CC}"
export MPITRAMPOLINE_CXX="${CXX}"
export MPITRAMPOLINE_FC="${FC}"

atomic_patch -p1 ../patches/libtoolize.patch
atomic_patch -p1 ../patches/mpi.patch

./autogen.sh
if [[ "${target}" != *-mingw* ]]; then
    # There is no mpicc on Windows
    CC=mpicc
    CXX=mpicxx    
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-lwgrp=${prefix} CC="${CC}" CXX="${CXX}"
make -j${nproc}
make install
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Dependency lwgrp has not been built for Windows
filter!(!Sys.iswindows, platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libdtcmp", :libdtcmp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # To ensure that the correct version of libgfortran is found at runtime
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("lwgrp_jll"; compat="1.0.7"),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
# (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"5")
