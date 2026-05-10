# PETSc with ILP64 BLAS via libblastrampoline (Julia stdlib),
# external SuiteSparse_jll, ILP64 SCALAPACK_jll, and static
# compilations of SuperLU_Dist, MUMPS, Hypre, Triangle and TetGen.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "PETSc"
version = v"3.24.6"

# Collection of sources required to build PETSc.
sources = [
    ArchiveSource("https://web.cels.anl.gov/projects/petsc/download/release-snapshots/petsc-$(version).tar.gz",
                  "d6ad14652996b0e0d3da51068eec902118057f275de867e8cf258ffd64d90a7d"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""

# so we can use a newer version of cmake
apk del cmake

cd $WORKSPACE/srcdir/petsc*

if [[ "${target}" == *-mingw* ]]; then
    # PETSc is built without MPI on Windows: linking against MSMPI
    # produces an mingw-w64 32-bit pseudo-relocation runtime failure
    # that has not been resolved (see PETSc_jll < 3.22 history).
    USE_MPI=0
    MPI_FFLAGS=""
    MPI_LIBS=""
    MPI_INC=""
else
    # Non-Windows: always MPIABI (the recipe filters all other MPI ABIs above).
    USE_MPI=1
    MPI_FFLAGS=""
    MPI_LIBS=--with-mpi-lib="[${libdir}/libmpif.${dlext},${libdir}/libmpi_abi.${dlext}]"
    MPI_INC=--with-mpi-include=${includedir}
fi

if [[ ${target} == *mingw* ]]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/mingw-version.patch
fi

# Tell PETSc that SuiteSparse_jll works with 64-bit BLAS indices.
# Otherwise PETSc's per-package `requires32bitintblas` default rejects
# the combination at configure time.
atomic_patch -p1 $WORKSPACE/srcdir/patches/suitesparse-64bit-blas.patch

mkdir $libdir/petsc
build_petsc()
{
    # so we can use a newer version of cmake
    apk del cmake

    # Compile a debug version?
    DEBUG_FLAG=0
    PETSC_CONFIG="${1}_${2}_${3}"
    if [[ "${4}" == "deb" ]]; then
        PETSC_CONFIG="${1}_${2}_${3}_deb"
        DEBUG_FLAG=1
    fi

    if [[ "${3}" == "Int64" ]]; then
        USE_INT64=1
    else
        USE_INT64=0
    fi

    # A SuperLU_DIST build is (now) available on most systems, but only works for double precision
    USE_SUPERLU_DIST=0
    if [ "${1}" == "double" ]; then
        USE_SUPERLU_DIST=1
    fi
    if [[ "${target}" == *-mingw* ]]; then
        USE_SUPERLU_DIST=0
    fi

    # SuiteSparse from Julia's stdlib SuiteSparse_jll (Int64-only,
    # double-precision only).  PETSc's umfpack glue calls _dl_/_zl_
    # symbols, which match what SuiteSparse_jll exports.
    USE_SUITESPARSE=0
    if [ "${1}" == "double" ]; then
        USE_SUITESPARSE=1
    fi

    # See if we can install MUMPS
    USE_MUMPS=0
    if [[ "${target}" == *-mingw* ]]; then
        # try static
        USE_MUMPS=0
    elif [ "${1}" == "double" ] && [ "${2}" == "real" ]; then
        USE_MUMPS=1
    else
        USE_MUMPS=0
    fi
    if [[ "${target}" == powerpc64le-linux-* ]] || [[ "${target}" == aarch64-linux-* ]] || [[ "${target}" == arm-linux-* ]]; then
        USE_MUMPS=0
    fi

    LDFLAGS="-L${libdir}"
    if [[ "${target}" == *-mingw* ]]; then
        # libssp for stack-smashing protection symbols on mingw.
        LDFLAGS="${LDFLAGS} -lssp"
    fi

    # External SuiteSparse from Julia's stdlib SuiteSparse_jll.
    if [ ${USE_SUITESPARSE} == 1 ]; then
        SUITESPARSE_ARGS="--with-suitesparse=1 --with-suitesparse-include=${includedir} --with-suitesparse-lib=[${libdir}/libspqr.${dlext},${libdir}/libumfpack.${dlext},${libdir}/libklu.${dlext},${libdir}/libcholmod.${dlext},${libdir}/libamd.${dlext},${libdir}/libcamd.${dlext},${libdir}/libcolamd.${dlext},${libdir}/libccolamd.${dlext},${libdir}/libbtf.${dlext},${libdir}/libsuitesparseconfig.${dlext}]"
    else
        SUITESPARSE_ARGS="--with-suitesparse=0"
    fi

    # SCALAPACK only on non-Windows (no Windows MPI build).
    if [[ "${target}" == *-mingw* ]]; then
        SCALAPACK_ARGS=""
    else
        SCALAPACK_ARGS="--with-scalapack-lib=${libdir}/libscalapack.${dlext} --with-scalapack-include=${includedir}"
    fi

    # ILP64 BLAS via libblastrampoline (PETSc calls dgemm_64_, etc.).
    # Julia >= 1.10 wires its stdlib OpenBLAS into LBT's ILP64 slots, so
    # no `__init__` forwarding is needed in PETSc_jll.  On Windows LBT
    # has historically been flaky, so link OpenBLAS_jll directly there.
    BLAS_LAPACK_LIB="${libdir}/libblastrampoline.${dlext}"
    CLINK_FLAGS=""
    if [[ "${target}" == aarch64-apple-* ]]; then
        # Linking requires the function `__divdc3`, which is implemented in
        # `libclang_rt.osx.a` from LLVM compiler-rt.
        CLINK_FLAGS="${CLINK_FLAGS} -L${libdir}/darwin -lclang_rt.osx"
    elif [[ "${target}" == *-mingw* ]]; then
        BLAS_LAPACK_LIB="${libdir}/libopenblas64_.${dlext}"
    fi

    if  [ ${DEBUG_FLAG} == 1 ]; then
        _COPTFLAGS='-O0 -g'
        _CXXOPTFLAGS='-O0 -g'
        _FOPTFLAGS='-O0'
    else
        _COPTFLAGS='-O3 -g'
        _CXXOPTFLAGS='-O3 -g'
        _FOPTFLAGS='-O3'
    fi

    # hypre
    USE_HYPRE=0
    if [ "${1}" == "double" ] && [ "${2}" == "real" ]; then
        USE_HYPRE=1
    fi

    if [[ "${target}" == *-mingw* ]]; then
        # No MPI on Windows: use raw compilers, and skip the
        # external packages that require an MPI build environment.
        MPI_CC=${CC}
        MPI_FC=${FC}
        MPI_CXX=${CXX}
        USE_SUPERLU_DIST=0
        USE_SUITESPARSE=0
        USE_HYPRE=0
    else
        MPI_CC=mpicc
        MPI_FC=mpifc
        MPI_CXX=mpicxx
        export MPIF_FCLIBS='-lmpif -lmpi_abi'
    fi
    if [[ "${target}" == powerpc64le-linux-* || "${target}" == aarch64-linux-* || "${target}" == arm-linux-* ]]; then
        USE_MUMPS=0
    fi

    # triangle, tetgen
    USE_TRIANGLE=0
    USE_TETGEN=0
    if [ "${1}" == "double" ] ; then
         USE_TRIANGLE=1
         USE_TETGEN=1
    fi

    # Define our toolchain for PETSc and all the other packages it configures recursively
    #
    # Don't know how to properly pass `CMAKE_INSTALL_PREFIX` to
    # SuiteSparse. Apparently the definition in our target toolchain
    # overrides whatever we pass by command line or via environment
    # variable. So we copy and modify our target toolchain.
    export CMAKE_INSTALL_PREFIX=${libdir}/petsc/${PETSC_CONFIG}
    export CMAKE_TOOLCHAIN_FILE=$(pwd)/cmake.toolchain.file
    sed -e 's+set(CMAKE_INSTALL_PREFIX $ENV{prefix})+set(CMAKE_INSTALL_PREFIX $ENV{CMAKE_INSTALL_PREFIX})+' <${CMAKE_TARGET_TOOLCHAIN} >${CMAKE_TOOLCHAIN_FILE}
    echo CMAKE_INSTALL_PREFIX:
    echo ${CMAKE_INSTALL_PREFIX}
    echo CMAKE_TOOLCHAIN_FILE:
    echo ${CMAKE_TOOLCHAIN_FILE}
    echo CMAKE_TOOLCHAIN_FILE:
    cat ${CMAKE_TOOLCHAIN_FILE}

    echo "USE_SUPERLU_DIST="$USE_SUPERLU_DIST
    echo "USE_SUITESPARSE="$USE_SUITESPARSE
    echo "USE_MUMPS="$USE_MUMPS
    echo "USE_HYPRE="$USE_HYPRE
    echo "USE_TETGEN="$USE_TETGEN
    echo "USE_TRIANGLE="$USE_TRIANGLE
    echo "1="${1}
    echo "2="${2}
    echo "3="${3}
    echo "4="${4}
    echo "USE_INT64"=$USE_INT64
    echo "Machine_name="$Machine_name
    echo "LDFLAGS="$LDFLAGS
    echo "target="$target
    echo "DEBUG="${DEBUG_FLAG}
    echo "COPTFLAGS="${_COPTFLAGS}
    echo "BLAS_LAPACK_LIB="$BLAS_LAPACK_LIB
    echo "prefix="${libdir}/petsc/${PETSC_CONFIG}
    echo "MPI_CC="$MPI_CC
    echo "MPI_FC="$MPI_FC
    echo "MPI_CXX="$MPI_CXX

    mkdir ${libdir}/petsc/${PETSC_CONFIG}

    # Step 1: build static libraries of external packages (happens during configure)
    # Note that mpicc etc. should be indicated rather than ${CC} to compile external packages
    ./configure --prefix=${libdir}/petsc/${PETSC_CONFIG} \
        --CC=${MPI_CC} \
        --FC=${MPI_FC} \
        --CXX=${MPI_CXX} \
        --COPTFLAGS=${_COPTFLAGS} \
        --CXXOPTFLAGS=${_CXXOPTFLAGS} \
        --FOPTFLAGS=${_FOPTFLAGS} \
        --with-blaslapack-lib=${BLAS_LAPACK_LIB} \
        --with-blaslapack-suffix=_64_ \
        --known-64-bit-blas-indices=1 \
        --CFLAGS="-fPIC -fno-stack-protector" \
        --CXXFLAGS="-fPIC -fno-stack-protector" \
        --FFLAGS="${MPI_FFLAGS} -fPIC -ffree-line-length-999" \
        --LDFLAGS="${LDFLAGS}" \
        --CC_LINKER_FLAGS="${CLINK_FLAGS}" \
        --with-64-bit-indices=${USE_INT64} \
        --with-debugging=${DEBUG_FLAG} \
        --with-batch \
        --with-mpi=${USE_MPI} \
        ${MPI_LIBS} \
        ${MPI_INC} \
        --with-sowing=0 \
        --with-precision=${1} \
        --with-scalar-type=${2} \
        --with-pthread=0 \
        --PETSC_ARCH=${target}_${PETSC_CONFIG} \
        ${SCALAPACK_ARGS} \
        ${SUITESPARSE_ARGS} \
        --download-superlu_dist=${USE_SUPERLU_DIST} \
        --download-superlu_dist-shared=0 \
        --download-hypre=${USE_HYPRE} \
        --download-hypre-shared=0 \
        --download-hypre-configure-arguments='--host --build' \
        --download-mumps=${USE_MUMPS} \
        --download-mumps-shared=0 \
        --download-tetgen=${USE_TETGEN} \
        --download-triangle=${USE_TRIANGLE} \
        --with-library-name-suffix=_${PETSC_CONFIG} \
        --with-shared-libraries=1 \
        --with-clean=1

    if [[ "${target}" == *-mingw* ]]; then
        export CPPFLAGS="-Dpetsc_EXPORTS"
    else
        export CFLAGS="-fPIC"
        export FFLAGS="-fPIC"
    fi

    make -j${nproc} \
        CPPFLAGS="${CPPFLAGS}" \
        CFLAGS="${CFLAGS}" \
        CXXFLAGS="${CXXFLAGS}" \
        FFLAGS="${FFLAGS}"
    make install

    # Remove PETSc.pc because petsc.pc also exists, causing conflicts on case-insensitive file-systems.
    rm ${libdir}/petsc/${PETSC_CONFIG}/lib/pkgconfig/PETSc.pc
    if  [[ "${1}" == "double" && "${2}" == "real" &&  "${3}" == "Int64" && "${4}" == "opt" ]]; then

        # Compile examples (to allow testing the installation).
        # This can later be run with:
        # julia> run(`$(PETSc_jll.ex42()) -stokes_ksp_monitor -log_view` )
        workdir=${libdir}/petsc/${PETSC_CONFIG}/share/petsc/examples/src/ksp/ksp/tutorials/
        make --directory=${workdir} PETSC_DIR=${libdir}/petsc/${PETSC_CONFIG} PETSC_ARCH=${target}_${PETSC_CONFIG} ex42
        file=${workdir}/ex42
        if [[ "${target}" == *-mingw* ]]; then
            if [[ -f "$file" ]]; then
                mv $file ${file}${exeext}
            fi
        fi
        install -Dvm 755 ${workdir}/ex42${exeext} "${bindir}/ex42${exeext}"

        # This is a staggered grid Stokes example, as discussed in https://joss.theoj.org/papers/10.21105/joss.04531
        # This can later be run with:
        # julia> run(`$(PETSc_jll.ex4()) -ksp_monitor -log_view` )
        workdir=${libdir}/petsc/${PETSC_CONFIG}/share/petsc/examples/src/dm/impls/stag/tutorials/
        make --directory=$workdir PETSC_DIR=${libdir}/petsc/${PETSC_CONFIG} PETSC_ARCH=${target}_${PETSC_CONFIG} ex4
        file=${workdir}/ex4
        if [[ "${target}" == *-mingw* ]]; then
            if [[ -f "$file" ]]; then
                mv $file ${file}${exeext}
            fi
        fi
        install -Dvm 755 ${workdir}/ex4${exeext} "${bindir}/ex4${exeext}"

        # this is the example that PETSc uses to test the correct installation
        workdir=${libdir}/petsc/${PETSC_CONFIG}/share/petsc/examples/src/snes/tutorials/
        make --directory=$workdir PETSC_DIR=${libdir}/petsc/${PETSC_CONFIG} PETSC_ARCH=${target}_${PETSC_CONFIG} ex19
        file=${workdir}/ex19
        if [[ "${target}" == *-mingw* ]]; then
            if [[ -f "$file" ]]; then
                mv $file ${file}${exeext}
            fi
        fi
        install -Dvm 755 ${workdir}/ex19${exeext} "${bindir}/ex19${exeext}"

    fi

    if [[ "${1}" == "double" && "${2}" == "real" && "${3}" == "Int64" && "${4}" == "deb" ]]; then

        # this is the example that PETSc uses to test the correct installation
        # We compile it with debug flags (helpful to catch issues)
        workdir=${libdir}/petsc/${PETSC_CONFIG}/share/petsc/examples/src/snes/tutorials/
        make --directory=$workdir PETSC_DIR=${libdir}/petsc/${PETSC_CONFIG} PETSC_ARCH=${target}_${PETSC_CONFIG} ex19
        file=${workdir}/ex19
        if [[ "${target}" == *-mingw* ]]; then
            if [[ -f "$file" ]]; then
                mv $file ${file}${exeext}
            fi
        fi
        mv ${file}${exeext} ${file}_int64_deb${exeext}
        install -Dvm 755 ${workdir}/ex19_int64_deb${exeext} "${bindir}/ex19_int64_deb${exeext}"

    fi

    # we don't particularly care about the other examples
    rm -r ${libdir}/petsc/${PETSC_CONFIG}/share/petsc/examples
}

build_petsc double real    Int64 opt
build_petsc double real    Int64 deb     # compile at least one debug version
build_petsc double complex Int64 opt
build_petsc single real    Int64 opt
build_petsc single complex Int64 opt
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# We attempt to build for all defined platforms
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# PETSc uses C++ internally, in particular `std::to_string`.
# (This is only used for debugging, and it would be straightforward to
# replace this by calls to `malloc`, `realloc`, and `snprintf`.)
platforms = expand_cxxstring_abis(platforms)

filter!(p -> nbits(p) != 32, platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Non-Windows: build only against MPIABI. Other MPI implementations
# (MPICH, MPItrampoline, OpenMPI) are reachable via MPIABI at runtime
# through MPIPreferences without rebuilding PETSc.
# Windows: pick MicrosoftMPI as the platform tag (only option), but
# PETSc itself is configured with --with-mpi=0 (see script above).
filter!(p -> p["mpi"] in ("mpiabi", "microsoftmpi"), platforms)

products = [
    ExecutableProduct("ex4", :ex4),
    ExecutableProduct("ex42", :ex42),
    ExecutableProduct("ex19", :ex19),
    ExecutableProduct("ex19_int64_deb", :ex19_int64_deb),

    # Default build, equivalent to Float64_Real_Int64
    LibraryProduct("libpetsc_double_real_Int64", :libpetsc, "\$libdir/petsc/double_real_Int64/lib"),
    LibraryProduct("libpetsc_double_real_Int64", :libpetsc_Float64_Real_Int64, "\$libdir/petsc/double_real_Int64/lib"),
    LibraryProduct("libpetsc_double_real_Int64_deb", :libpetsc_Float64_Real_Int64_deb, "\$libdir/petsc/double_real_Int64_deb/lib"),
    LibraryProduct("libpetsc_double_complex_Int64", :libpetsc_Float64_Complex_Int64, "\$libdir/petsc/double_complex_Int64/lib"),
    LibraryProduct("libpetsc_single_real_Int64", :libpetsc_Float32_Real_Int64, "\$libdir/petsc/single_real_Int64/lib"),
    LibraryProduct("libpetsc_single_complex_Int64", :libpetsc_Float32_Complex_Int64, "\$libdir/petsc/single_complex_Int64/lib"),
]

dependencies = [
    HostBuildDependency(PackageSpec(; name="CMake_jll")),

    BuildDependency("LLVMCompilerRT_jll"; platforms=filter(Sys.isapple, platforms)),

    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    # ILP64 BLAS: OpenBLAS_jll on Windows (linked directly), libblastrampoline_jll on
    # everything else (Julia >= 1.7 wires its stdlib OpenBLAS into LBT's ILP64 slots).
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363");
               platforms=filter(Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93");
               compat="5.4.0",
               platforms=filter(!Sys.iswindows, platforms)),
    # ILP64 SCALAPACK to match the BLAS ABI.  No Windows build (PETSc has
    # MPI disabled on Windows so SCALAPACK isn't needed there either).
    Dependency(PackageSpec(name="SCALAPACK_jll", uuid="5d3fc3e8-a677-5550-826f-6cfd58f208da");
               compat="2.2.2", platforms=filter(!Sys.iswindows, platforms)),
    # Julia's stdlib SuiteSparse (Int64 / SuiteSparse_long).  Julia
    # 1.10 ships SuiteSparse_jll 7.2.x.
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"); compat="7.2.0"),
    Dependency("mpif_jll"; compat="0.1.5", platforms=filter(p -> p["mpi"] == "mpiabi", platforms)), # MPI Fortran bindings
]
append!(dependencies, platform_dependencies)

# Build the tarballs.
# NOTE: llvm16 seems to have an issue with PETSc 3.18.x as on apple architectures it doesn't know how to create dynamic libraries
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, clang_use_lld=false, julia_compat="1.10", preferred_gcc_version=v"9")
