using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "QuantumEspresso"
# When updating to 7.5+ (as of 2nd of July 2025 not yet released),
# it should be possible to remove 0002-kcw-parallel-make.patch.
version = v"7.4.1"

sources = [
    ArchiveSource("https://gitlab.com/QEF/q-e/-/archive/qe-$(version)/q-e-qe-$(version).tar.gz",
                  "6ef9c53dbf0add2a5bf5ad2a372c0bff935ad56c4472baa001003e4f932cab97"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd q-e-qe-*
atomic_patch -p1 ../patches/0000-pass-host-to-configure.patch
atomic_patch ../patches/0002-kcw-parallel-make.patch

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
# Not supported by Libxc JLL
filter!(p -> !(Sys.islinux(p) && arch(p) == "aarch64" && libgfortran_version(p) <= v"4"), platforms)
# "Old-style type declaration REAL*16 not supported" in merge_wann.f90
filter!(p -> !(Sys.islinux(p) && (arch(p) == "armv6l" || arch(p) == "armv7l")), platforms)
# Not supported by OpenBLAS32 JLL
filter!(p -> !(arch(p) == "powerpc64le" && libgfortran_version(p) < v"5"), platforms)
# Not supported by SCALAPACK32 JLL
filter!(p -> arch(p) != "riscv64", platforms)

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
    ExecutableProduct("band_interpolation.x", :band_interpolation),
    ExecutableProduct("cppp.x", :cppp),
    ExecutableProduct("d3hess.x", :d3hess),
    ExecutableProduct("kcw.x", :kcw),
    ExecutableProduct("ld1.x", :ld1),
    ExecutableProduct("molecularpdos.x", :molecularpdos),
    ExecutableProduct("oscdft_et.x", :oscdft_et),
    ExecutableProduct("oscdft_pp.x", :oscdft_pp),
    ExecutableProduct("postahc.x", :postahc),
    ExecutableProduct("pp.x", :pp),
    ExecutableProduct("ppacf.x", :ppacf),
    ExecutableProduct("pprism.x", :pprism),
    ExecutableProduct("projwfc.x", :projwfc),
    ExecutableProduct("pw2bgw.x", :pw2bgw),
    ExecutableProduct("pw2wannier90.x", :pw2wannier90),
    ExecutableProduct("pwcond.x", :pwcond),
    ExecutableProduct("turbo_davidson.x", :turbo_davidson),
    ExecutableProduct("turbo_eels.x", :turbo_eels),
    ExecutableProduct("turbo_lanczos.x", :turbo_lanczos),
    ExecutableProduct("turbo_magnon.x", :turbo_magnon),
    ExecutableProduct("turbo_spectrum.x", :turbo_spectrum),
    ExecutableProduct("xspectra.x", :xspectra),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("FFTW_jll"),
    Dependency("Libxc_jll"),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    Dependency(PackageSpec(name="SCALAPACK32_jll", uuid="aabda75e-bfe4-5a37-92e3-ffe54af3c273"); compat="2.1.0 - 2.2.1"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"6")
