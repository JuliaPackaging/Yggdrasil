using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "QuantumEspresso"
version = v"7.1"
quantumespresso_version = v"7.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.com/QEF/q-e/-/archive/qe-7.1/q-e-qe-7.1.tar.gz",
        "d56dea096635808843bd5a9be2dee3d1f60407c01dbeeda03f8256a3bcfc4eb6"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd q-e-qe-*
atomic_patch -p1 ../patches/0000-pass-host-to-configure-7.1.patch

export BLAS_LIBS="-L${libdir} -lopenblas"
export LAPACK_LIBS="-L${libdir} -lopenblas"
export FFTW_INCLUDE=${includedir}
export FFT_LIBS="-L${libdir} -lfftw3"
export MPITRAMPOLINE_FC=gfortran
export MPITRAMPOLINE_CC=cc
if which mpif90; then
    export FC=mpif90
else
    export FC=mpifort
fi
export CC=mpicc
export LD=

flags=(--enable-parallel=yes)
if [ "${nbits}" == 64 ]; then
    # Enable Libxc support only on 64-bit platforms
    atomic_patch -p1 ../patches/0001-libxc-prefix.patch
    flags+=(--with-libxc=yes --with-libxc-prefix=${prefix})
fi

if [ -e ${libdir}/libscalapack32.* ]; then
    export SCALAPACK_LIBS="-L${libdir} -lscalapack32"
    flags+=(--with-scalapack=yes)
else
    # No scalapack binary available on this platforms
    flags+=(--with-scalapack=no)
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} ${flags[@]}
make all "${make_args[@]}" -j $nproc
make install
# Manually make all binary executables...executable.  Sigh
chmod +x "${bindir}"/*
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())
filter!(!Sys.iswindows, platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# MPItrampoline is not supported
filter!(p -> p["mpi"] ≠ "mpitrampoline", platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
filter!(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
filter!(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
filter!(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("pw.x", :pwscf),
    ExecutableProduct("bands.x", :bands),
    ExecutableProduct("plotband.x", :plotband),
    ExecutableProduct("plotrho.x", :plotrho),
    ExecutableProduct("dos.x", :density_of_states),
    ExecutableProduct("ibrav2cell.x", :ibrav_to_cell),
    ExecutableProduct("kpoints.x", :kpoints),
    ExecutableProduct("cp.x", :carparinello),
    ExecutableProduct("ph.x", :phonon),
    ExecutableProduct("q2r.x", :reciprocal_to_real),
    ExecutableProduct("matdyn.x", :dynamical_matrix_generic),
    ExecutableProduct("dynmat.x", :dynamical_matrix_gamma),
    ExecutableProduct("hp.x", :hubbardparams),
    ExecutableProduct("neb.x", :nudged_elastic_band),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("FFTW_jll"),
    Dependency("Libxc_jll"),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    Dependency("SCALAPACK32_jll"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"10.2.0")
