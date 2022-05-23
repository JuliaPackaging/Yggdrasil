using BinaryBuilder, Pkg

name = "QuantumEspresso"
version = v"7.0.0"

sources = [
    ArchiveSource("https://gitlab.com/QEF/q-e/-/archive/qe-7.0/q-e-qe-7.0.tar.gz",
                  "85beceb1aaa1678a49e774c085866d4612d9d64108e0ac49b23152c8622880ee"),
    DirectorySource("bundled"),
]


# Bash recipe for building across all platforms
script = raw"""
cd q-e-qe-*
atomic_patch -p1 ../patches/0000-pass-host-to-configure.patch

export BLAS_LIBS="-L${libdir} -lopenblas"
export LAPACK_LIBS="-L${libdir} -lopenblas"
export FFTW_INCLUDE=${includedir}
export FFT_LIBS="-L${libdir} -lfftw3"
export FC=mpif90
export CC=mpicc
export LD=

flags=(--enable-parallel=yes)
if [ "${nbits}" == 64 ]; then
    # Enable Libxc support only on 64-bit platforms
    atomic_patch -p1 ../patches/0001-libxc-prefix.patch
    flags+=(--with-libxc=yes --with-libxc-prefix=${prefix})
fi

if [[    "${target}" == powerpc64le-linux-* \
      || "${bb_full_target}" == armv6l-linux-* \
      || "${target}" == aarch64-apple-darwin* ]]; then
    # No scalapack binary available on these platforms
    flags+=(--with-scalapack=no)
else
    export SCALAPACK_LIBS="-L${libdir} -lscalapack"
    flags+=(--with-scalapack=yes)
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} ${flags[@]}
make all "${make_args[@]}" -j $nproc
make install
# Manually make all binary executables...executable.  Sigh
chmod +x "${bindir}"/*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())
filter!(!Sys.iswindows, platforms)
# On aarch64-apple-darwin we get
#    f951: internal compiler error: in doloop_contained_procedure_code, at fortran/frontend-passes.c:2464
filter!(p -> !(Sys.isapple(p) && arch(p) == "aarch64"), platforms)

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
    Dependency("MPICH_jll"),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    Dependency("SCALAPACK_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"6", julia_compat="1.6")
