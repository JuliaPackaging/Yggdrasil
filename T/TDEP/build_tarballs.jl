using BinaryBuilder
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
# include("mpi.jl")

name = "TDEP"
version = v"24.09"
sources = [
    GitSource("https://github.com/tdep-developers/tdep.git", "8579c30cce7a3d78c2a88535cda247e0c00eb1a9"),
    DirectorySource("./bundled") # contents will be copied to ${WORKSPACE}/srcdir
]

# IF OPENMPI USE -lmpi -lmpi_mpifh
# IF MPICH USE -lmpi -lmpifort

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

bash ${WORKSPACE}/srcdir/make_important_settings.sh
bash build_things.sh --clean --nomanpage --nthreads_make ${nproc}


export LDFLAGS="-L${libdir}"
cp ../Makefile.shared ./src/libolle/SharedMakefile
cp ../Makefile.install ./src/libolle/InstallMakefile

cd ./src/libolle
make -f SharedMakefile -j ${nproc}

make -f InstallMakefile install BB_bindir=${bindir} BB_libdir=${libdir}

install_license ${WORKSPACE}/srcdir/tdep/LICENSE.md ${WORKSPACE}/srcdir/tdep/CITATION.cff
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = supported_platforms()
# platforms = [Platform("x86_64", "linux", libc=:glibc)]

# This breaks things, I expect its cause I used GCC10
# platforms = expand_gfortran_versions(platforms) 

# TODO REMOVE i686-linux-musl
# platforms = filter(p -> os(p) == "linux" || os(p) == "macos", platforms) # could support others, but lets get it working first
platforms = filter(p -> os(p) == "linux", platforms) # could support others, but lets get it working first
platforms = filter(p -> arch(p) != "riscv64", platforms) # Doesn't work with gcc10 it seems
platforms = filter(p -> nbits(p) ≠ 32, platforms) # Only support 64-bit platforms


# We need to use the same compat bounds as HDF5
platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.5.0", OpenMPI_compat="4.1.6, 5")

# Avoid platforms where the MPI implementation isn't supported
platforms = filter(p -> !(p["mpi"] == "openmpi" && Sys.isfreebsd(p)), platforms)
# platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)


# Only use OpenMPI or MPICH, add windows here later if desired
platforms = filter(p -> (p["mpi"] == "mpich" || p["mpi"] == "openmpi"), platforms)

# println(platform_dependencies)
# println(platforms)

products = [
    LibraryProduct("libolle", :libolle), #there is libolle.a and .so, this grabs the shared version I think
    ExecutableProduct("generate_structure", :generate_structure),
    ExecutableProduct("canonical_configuration", :canonical_configuration),
    ExecutableProduct("extract_forceconstants", :extract_forceconstants),
    ExecutableProduct("phonon_dispersion_relations", :phonon_dispersion_relations),
    ExecutableProduct("thermal_conductivity", :thermal_conductivity),
    # ExecutableProduct("thermal_conductivity_2023", :thermal_conductivity_2023),
    ExecutableProduct("lineshape", :lineshape),
    ExecutableProduct("anharmonic_free_energy", :anharmonic_free_energy),
    ExecutableProduct("atomic_distribution", :atomic_distribution),
    ExecutableProduct("pack_simulation", :pack_simulation),
    ExecutableProduct("samples_from_md", :samples_from_md),
    ExecutableProduct("dump_dynamical_matrices", :dump_dynamical_matrices),
    ExecutableProduct("crystal_structure_info", :crystal_structure_info),
    ExecutableProduct("refine_structure", :refine_structure),
    ExecutableProduct("phasespace_surface", :phasespace_surface)
]

dependencies = [
    Dependency("HDF5_jll"), Dependency("FFTW_jll"), Dependency("OpenBLAS32_jll") # Dependency("LAPACK_jll")
]

# This will add the MPI dependencies
# This also adds Microsoft_JLL and MPITrampoline even though I don't need those
append!(dependencies, platform_dependencies)
println("DEPS: $(dependencies)")

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                 augment_platform_block, julia_compat = "1.6", preferred_gcc_version = v"10")

