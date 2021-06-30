using BinaryBuilder, Pkg

name = "QuantumEspresso"
version = v"6.7.0"

# TODO This build still suffers from some limitations:
#      - Missing SCALAPACK support

sources = [
    ArchiveSource("https://github.com/QEF/q-e/releases/download/qe-6.7.0/qe-6.7-ReleasePack.tgz",
                  "8f06ea31ae52ad54e900a2f51afd5c70f78096d9dcf39c86c2b17dccb1ec9c87"),
    DirectorySource("bundled"),
]


# Bash recipe for building across all platforms
script = raw"""
    cd qe-*
    atomic_patch -p1 ../patches/0000-pass-host-to-configure.patch
    atomic_patch -p1 ../patches/0001-libxc-prefix.patch

    export BLAS_LIBS="-L${libdir} -lopenblas"
    export LAPACK_LIBS="-L${libdir} -lopenblas"
    export FFTW_INCLUDE=${includedir} FFT_LIBS="-L${libdir} -lfftw3"
    export MPIF90=mpif90
    export CC=mpicc
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
        --enable-parallel=yes --with-scalapack=no \
        --with-libxc=yes --with-libxc-prefix=${prefix}
    make all "${make_args[@]}" -j $nproc MPIF90=mpif90 CC=mpicc
    make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())
platforms = filter!(!Sys.iswindows, platforms)
platforms = filter!(!Sys.isapple, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("pw.x", :pwscf),
    ExecutableProduct("cp.x", :carparinello),
    ExecutableProduct("ph.x", :phonon),
    ExecutableProduct("hp.x", :hubbardparams),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("FFTW_jll"),
    Dependency("Libxc_jll"),
    Dependency("MPICH_jll"),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"5", julia_compat="1.6")
