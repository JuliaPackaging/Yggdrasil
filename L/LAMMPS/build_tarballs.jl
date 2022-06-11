# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "LAMMPS"
version = v"2.2.2" # Equivalent to 29Sep2021_update2

# Version table
# 1.0.0 -> https://github.com/lammps/lammps/releases/tag/stable_29Oct2020
# 2.0.0 -> https://github.com/lammps/lammps/releases/tag/stable_29Sep2021
# 2.2.0 -> https://github.com/lammps/lammps/releases/tag/stable_29Sep2021_update2

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lammps/lammps.git", "7586adbb6a61254125992709ef2fda9134cfca6c")
]

# Bash recipe for building across all platforms
# LAMMPS DPD packages do not work on all platforms
script = raw"""
cd $WORKSPACE/srcdir/lammps/
mkdir build && cd build/
cmake -C ../cmake/presets/most.cmake -C ../cmake/presets/nolib.cmake ../cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DLAMMPS_EXCEPTIONS=ON \
    -DPKG_MPI=ON \
    -DPKG_ML-SNAP=ON \
    -DPKG_ML-PACE=ON \
    -DPKG_DPD-BASIC=OFF \
    -DPKG_DPD-MESO=OFF \
    -DPKG_DPD-REACT=OFF \
    -DPKG_USER-MESODPD=OFF \
    -DPKG_USER-DPD=OFF \
    -DPKG_USER-SDPD=OFF \
    -DPKG_DPD-SMOOTH=OFF

make -j${nproc}
make install

if [[ "${target}" == *mingw* ]]; then
    cp *.dll ${prefix}/bin/
fi
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    function augment_platform!(platform::Platform)
        augment_mpi!(platform)
    end
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = supported_platforms(; experimental=true)
platforms = supported_platforms()
platforms = filter(p -> !(Sys.isfreebsd(p) || libc(p) == "musl"), platforms)

# We need this since currently MPItrampoline_jll has a dependency on gfortran
platforms = expand_gfortran_versions(platforms)
# libgfortran3 does not support `!GCC$ ATTRIBUTES NO_ARG_CHECK`. (We
# could in principle build without Fortran support there.)
platforms = filter(p -> libgfortran_version(p) ≠ v"3", platforms)
# Compiler failure
filter!(p -> !(Sys.islinux(p) && arch(p) == "aarch64" && libc(p) =="glibc" && libgfortran_version(p) == v"4") , platforms)

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liblammps", :liblammps),
    ExecutableProduct("lmp", :lmp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll")),
]

all_platforms, platform_dependencies = MPI.augment_platforms(platforms)
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, all_platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8",
               augment_platform_block)

# bump

