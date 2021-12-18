# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "LAMMPS"
version = v"1.0.1" # Equivalent to 2020-10-29

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lammps/lammps.git", "88fd96ec52f86dba4b222623f3a06632a32e42f1")
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
	-DPKG_SNAP=ON \
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

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liblammps", :liblammps),
    ExecutableProduct("lmp", :lmp),
]

mpi_abis = (
    (:MPICH, PackageSpec(name="MPICH_jll"), "", !Sys.iswindows) ,
    # (:OpenMPI, PackageSpec(name="OpenMPI"), "", !Sys.iswindows),
    (:MicrosoftMPI, PackageSpec(name="MicrosoftMPI_jll"), "", Sys.iswindows),
    (:MPITrampoline, PackageSpec(name="MPItrampoline_jll"), "2", !Sys.iswindows)
)

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll")),
    Dependency(PackageSpec(name="MPIABI")),
]

all_platforms = AbstractPlatform[]
for (abi, pkg, compat, f) in mpi_abis
    pkg_platforms = deepcopy(filter(f, platforms))
    foreach(pkg_platforms) do p
        BinaryPlatforms.add_tag!(p.tags, "mpi", string(abi))
    end
    append!(all_platforms, pkg_platforms)
    push!(dependencies, Dependency(pkg; compat, platforms=pkg_platforms))
end

augment_platform_block = """
using Base.BinaryPlatforms
import MPIABI

function augment_platform!(platform)
    abi = MPIABI.abi
    BinaryPlatforms.add_tag!(platform.tags, "mpi", string(abi))
    return platform
end
"""
# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, all_platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8", augment_platform_block)
