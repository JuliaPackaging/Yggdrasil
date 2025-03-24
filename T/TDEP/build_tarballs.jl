using BinaryBuilder
using Base.BinaryPlatforms
import Pkg: PackageSpec

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "TDEP"
version = v"24.09"
sources = [
    GitSource("https://github.com/ejmeitz/tdep.git", "55e97dc98e8f85e8f607f2549e62d7f8d10357ac"),
    DirectorySource("./bundled")
]


script = raw"""

case ${bb_full_target} in
    *mpich*)
        export MPI_LIBS="-lmpifort -lmpi"
        ;;
    *openmpi*)
        export MPI_LIBS="-lmpi_mpifh -lmpi"
        # TDEP expcets MPI mod files in the include dir
        cd ${libdir}
        cp ./*.mod ../include/
        ;;
esac


cd ${WORKSPACE}/srcdir/tdep

if [[ ${target} == x86_64-linux-musl ]]; then
    # HDF5 needs libcurl, and it needs to be the BinaryBuilder libcurl, not the system libcurl.
    # MPI needs libevent, and it needs to be the BinaryBuilder libevent, not the system libevent.
    rm /usr/lib/libcurl.*
    rm /usr/lib/libevent*
    rm /usr/lib/libnghttp2.*
fi

export LDFLAGS="-L${libdir} -L${WORKSPACE}srcdir/tdep/build/libolle"

bash ${WORKSPACE}/srcdir/make_important_settings.sh
bash build_things.sh --clean --nomanpage --nthreads_make ${nproc} --install

install_license ${WORKSPACE}/srcdir/tdep/LICENSE.md ${WORKSPACE}/srcdir/tdep/CITATION.cff
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = supported_platforms()

# Do no support Windows (yet)
platforms = filter(p -> os(p) == "linux" || os(p) == "macos", platforms)

# Remove RiscV until thats something someone actually wants
platforms = filter(p -> arch(p) != "riscv64", platforms)

# No 32-bit support
platforms = filter(p -> nbits(p) != 32, platforms)

# TDEP uses Fortran 2008 features
# libgfortran 3 & 4 always crash with syntax issues
platforms = expand_gfortran_versions(platforms) 
platforms = filter(p -> libgfortran_version(p) >= v"5.0.0", platforms)

# Need to use the same compat bounds as HDF5
platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.5.0", OpenMPI_compat="4.1.6, 5")

# Avoid platforms where the MPI implementation isn't supported
platforms = filter(p -> !(p["mpi"] == "openmpi" && Sys.isfreebsd(p)), platforms)

# Only use OpenMPI or MPICH, add windows here later if desired
platforms = filter(p -> (p["mpi"] == "mpich" || p["mpi"] == "openmpi"), platforms)


products = [
    LibraryProduct("libolle", :libolle),
    ExecutableProduct("generate_structure", :generate_structure),
    ExecutableProduct("canonical_configuration", :canonical_configuration),
    ExecutableProduct("extract_forceconstants", :extract_forceconstants),
    ExecutableProduct("phonon_dispersion_relations", :phonon_dispersion_relations),
    ExecutableProduct("thermal_conductivity", :thermal_conductivity),
    ExecutableProduct("thermal_conductivity_2023", :thermal_conductivity_2023),
    ExecutableProduct("lineshape", :lineshape),
    ExecutableProduct("anharmonic_free_energy", :anharmonic_free_energy),
    ExecutableProduct("atomic_distribution", :atomic_distribution),
    ExecutableProduct("pack_simulation", :pack_simulation),
    ExecutableProduct("samples_from_md", :samples_from_md),
    ExecutableProduct("dump_dynamical_matrices", :dump_dynamical_matrices),
    ExecutableProduct("crystal_structure_info", :crystal_structure_info),
    ExecutableProduct("refine_structure", :refine_structure),
    # ExecutableProduct("phasespace_surface", :phasespace_surface)
]

dependencies = [
    Dependency("HDF5_jll"),
    Dependency("FFTW_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# This will add the MPI dependencies
append!(dependencies, platform_dependencies)

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                 augment_platform_block, julia_compat = "1.6", preferred_gcc_version = v"10")

