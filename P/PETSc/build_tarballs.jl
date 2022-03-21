using BinaryBuilder, Pkg

name = "PETSc"
version = v"3.16.5"

# Collection of sources required to build PETSc. Avoid using the git repository, it will
# require building SOWING which fails in all non-linux platforms.
sources = [
    ArchiveSource("https://www.mcs.anl.gov/petsc/mirror/release-snapshots/petsc-$(version).tar.gz",
    "7de8570eeb94062752d82a83208fc2bafc77b3f515023a4c14d8ff9440e66cac"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/petsc*
atomic_patch -p1 $WORKSPACE/srcdir/patches/petsc_name_mangle.patch

BLAS_LAPACK_LIB="${libdir}/libopenblas.${dlext}"


if [[ "${target}" == *-mingw* ]]; then
    #atomic_patch -p1 $WORKSPACE/srcdir/patches/fix-header-cases.patch
    MPI_LIBS="${libdir}/msmpi.${dlext}"
else
    MPI_LIBS="[${libdir}/libmpifort.${dlext},${libdir}/libmpi.${dlext}]"
fi
mkdir ${libdir}/petsc
build_petsc()
{

    if [[ "${3}" == "Int64" ]]; then
        USE_INT64=1
    else
        USE_INT64=0
    fi

    USE_MUMPS=1
    USE_SUPERLU_DIST=1
    USE_SUITESPARSE=1
    USE_PASTIX=1

    if [[ "${1}" == "single" ]]; then
        USE_SUITESPARSE=0
        USE_SUPERLU_DIST=0
    elif [[ "${3}" == "Int64" ]]; then
        USE_SUITESPARSE=0
    elif [[ "${1}" == "single" ]] && [[ "${2}" == "complex" ]]; then
        USE_SUITESPARSE=0
    fi

    if [[ "${target}" == *-apple* ]]; then
        # This fails because of a linker problem (-soname should be -dynamic_name)
        USE_SUPERLU_DIST=0
    fi;

    mkdir $libdir/petsc/${1}_${2}_${3}

    if [[ "${target}" == *-mingw* ]]; then
        # Windows machines
        #  Note: the reason to split this up in two configures, rather than one with $FLAGS is that passing
        #  such a $FLAG to, for example, CFLAGS=$FLAGS does not seem to work (not sure why).

        USE_SUPERLU_DIST=0
        CFLAGS="-fno-stack-protector -Wl,--enable-stdcall-fixup"
        CXXFLAGS="-fno-stack-protector -Wl,--enable-stdcall-fixup"
        EXTRA_ARGS=(
            --with-superlu_dist=${USE_SUPERLU_DIST}
            --download-superlu_dist-commit=v7.1.1
        )
    else
        # Non windows

        # Superlu_dist expects this:
        CC=mpicc
        FC=mpif90
        CXX=mpicxx
        CFLAGS="-fno-stack-protector"
        CXXFLAGS="-fno-stack-protector"
        EXTRA_ARGS=(
            --download-mumps=${USE_MUMPS}
            --with-scalapack=${USE_MUMPS}
            --with-scalapack-lib=${libdir}/libscalapack32.${dlext}
            --download-suitesparse=${USE_SUITESPARSE}
            --with-suitesparse=${USE_SUITESPARSE}
            --download-superlu_dist=${USE_SUPERLU_DIST}
            --with-sowing=0
            --with-clean=1
        )
    fi

    ./configure --prefix=${libdir}/petsc/${1}_${2}_${3} \
    CC=${CC} \
    FC=${FC} \
    CXX=${CXX} \
    COPTFLAGS='-O3' \
    CXXOPTFLAGS='-O3' \
    CFLAGS="${CFLAGS}" \
    CPPFLAGS="${CXXFLAGS}" \
    LDFLAGS="-L${libdir}" \
    FOPTFLAGS='-O3' \
    --with-64-bit-indices=${USE_INT64} \
    --with-debugging=0 \
    --with-batch \
    --with-blaslapack-lib=$BLAS_LAPACK_LIB \
    --with-blaslapack-suffix="" \
    --known-64-bit-blas-indices=0 \
    --with-mpi-lib="${MPI_LIBS}" \
    --known-mpi-int64_t=0 \
    --with-mpi-include="${includedir}" \
    --with-precision=${1} \
    --with-scalar-type=${2} \
    --PETSC_ARCH=${target}_${1}_${2}_${3} \
    "${EXTRA_FLAGS[@]}"

    if [[ "${target}" == *-mingw* ]]; then
        export CPPFLAGS="-Dpetsc_EXPORTS"
        CFLAGS=""
    elif [[ "${target}" == powerpc64le-* ]]; then
        export CFLAGS="-fPIC"
        export FFLAGS="-fPIC"
    fi

    make -j${nproc} \
        CPPFLAGS="${CPPFLAGS}" \
        CFLAGS="${CFLAGS}" \
        FFLAGS="${FFLAGS}"
    make install

    if [[ "${target}" == *-apple* ]]; then
        mv ${libdir}/petsc/${1}_${2}_${3}/lib/libpetsc.*.*.*.${dlext} "${libdir}/petsc/${1}_${2}_${3}/lib/libpetsc_${1}_${2}_${3}.${dlext}"
        install_name_tool -id libpetsc_${1}_${2}_${3}.${dlext} ${libdir}/petsc/${1}_${2}_${3}/lib/libpetsc_${1}_${2}_${3}.${dlext}
    else # windows and linux:
        mv ${libdir}/petsc/${1}_${2}_${3}/lib/libpetsc.${dlext}.*.*.* "${libdir}/petsc/${1}_${2}_${3}/lib/libpetsc_${1}_${2}_${3}.${dlext}"
    fi
    if [[ "${target}" == *-linux* ]]; then
        patchelf --set-soname "libpetsc_${1}_${2}_${3}.${dlext}" ${libdir}/petsc/${1}_${2}_${3}/lib/libpetsc_${1}_${2}_${3}.${dlext}
    fi

    # Remove now broken links
    rm ${libdir}/petsc/${1}_${2}_${3}/lib/libpetsc.*

    # Remove PETSc.pc because petsc.pc also exists, causing conflicts on case insensitive file-systems.
    rm ${libdir}/petsc/${1}_${2}_${3}/lib/pkgconfig/PETSc.pc
    sed -i -e "s/-lpetsc/-lpetsc_${1}_${2}_${3}/g" "$libdir/petsc/${1}_${2}_${3}/lib/pkgconfig/petsc.pc"
    mv $libdir/petsc/${1}_${2}_${3}/lib/pkgconfig/petsc.pc ${prefix}/lib/pkgconfig/petsc_${1}_${2}_${3}.pc


}

build_petsc double real Int32
build_petsc single real Int32
build_petsc double complex Int32
build_petsc single complex Int32
build_petsc double real Int64
build_petsc single real Int64
build_petsc double complex Int64
build_petsc single complex Int64
"""

# We attempt to build for all defined platforms
platforms = expand_gfortran_versions(supported_platforms())

products = [
    # Current default build, equivalent to Float64_Real_Int32
    LibraryProduct("libpetsc_double_real_Int32", :libpetsc, "\$libdir/petsc/double_real_Int32/lib")
    LibraryProduct("libpetsc_double_real_Int32", :libpetsc_Float64_Real_Int32, "\$libdir/petsc/double_real_Int32/lib")

    LibraryProduct("libpetsc_single_real_Int32", :libpetsc_Float32_Real_Int32, "\$libdir/petsc/single_real_Int32/lib")
    LibraryProduct("libpetsc_double_complex_Int32", :libpetsc_Float64_Complex_Int32, "\$libdir/petsc/double_complex_Int32/lib")
    LibraryProduct("libpetsc_single_complex_Int32", :libpetsc_Float32_Complex_Int32, "\$libdir/petsc/single_complex_Int32/lib")
    LibraryProduct("libpetsc_double_real_Int64", :libpetsc_Float64_Real_Int64, "\$libdir/petsc/double_real_Int64/lib")
    LibraryProduct("libpetsc_single_real_Int64", :libpetsc_Float32_Real_Int64, "\$libdir/petsc/single_real_Int64/lib")

    LibraryProduct("libpetsc_double_complex_Int64", :libpetsc_Float64_Complex_Int64, "\$libdir/petsc/double_complex_Int64/lib")
    LibraryProduct("libpetsc_single_complex_Int64", :libpetsc_Float32_Complex_Int64, "\$libdir/petsc/single_complex_Int64/lib")
]

dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"); platforms=filter(!Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="MicrosoftMPI_jll", uuid="9237b28f-5490-5468-be7b-bb81f5f5e6cf"); platforms=filter(Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="SCALAPACK32_jll", uuid="aabda75e-bfe4-5a37-92e3-ffe54af3c273"); platforms=filter(!Sys.iswindows, platforms)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")
