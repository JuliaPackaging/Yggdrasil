# PETSc linked against Julia's stdlib ILP64 SuiteSparse_jll, which forces
# ILP64 BLAS (via libblastrampoline `_64_` suffixes) for PETSc itself.
# Every other external package comes from Yggdrasil-built shared JLLs in
# its most convenient form: HYPRE64_jll and SuperLU_DIST_jll (Int64) match
# the 64-bit PetscInt; MUMPS_jll keeps its stock 32-bit integers (PETSc's
# supported PetscMUMPSInt=int32 path) and brings its own LP64 SCALAPACK32
# and BLAS (forwarded to OpenBLAS32 through libblastrampoline's LP64 slot)
# as private shared-library dependencies.  PETSc links no ScaLAPACK of its
# own.  Nothing is built or linked statically.
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
atomic_patch -p1 $WORKSPACE/srcdir/patches/external-pkgs-64bit-blas.patch

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

    # External MUMPS from MUMPS_jll (stock 32-bit integers; PETSc's
    # supported PetscMUMPSInt=int32 path).  Not on Windows: PETSc has
    # MPI disabled there.
    USE_MUMPS=0
    if [ "${1}" == "double" ] && [ "${2}" == "real" ] && [[ "${target}" != *-mingw* ]]; then
        USE_MUMPS=1
    fi

    LDFLAGS="-L${libdir}"
    if [[ "${target}" == *-mingw* ]]; then
        # libssp for stack-smashing protection symbols on mingw.
        LDFLAGS="${LDFLAGS} -lssp"
    fi

    # External SuiteSparse from Julia's stdlib SuiteSparse_jll.
    # SuiteSparse_jll >= 7.8 installs its headers under include/suitesparse.
    if [ ${USE_SUITESPARSE} == 1 ]; then
        SUITESPARSE_ARGS="--with-suitesparse=1 --with-suitesparse-include=${includedir}/suitesparse --with-suitesparse-lib=[${libdir}/libspqr.${dlext},${libdir}/libumfpack.${dlext},${libdir}/libklu.${dlext},${libdir}/libcholmod.${dlext},${libdir}/libamd.${dlext},${libdir}/libcamd.${dlext},${libdir}/libcolamd.${dlext},${libdir}/libccolamd.${dlext},${libdir}/libbtf.${dlext},${libdir}/libsuitesparseconfig.${dlext}]"
    else
        SUITESPARSE_ARGS="--with-suitesparse=0"
    fi

    # No --with-scalapack: PETSc's own MatScaLAPACK type is hardwired to
    # the `_64_` BLAS suffix, while MUMPS uses the LP64 libscalapack32
    # that MUMPS_jll's shared libraries link privately.  Mixing an ILP64
    # and an LP64 ScaLAPACK in one process is unsafe (they export ~370
    # identical BLACS-internal symbols, e.g. BI_* and Cblacs_*, that
    # would cross-bind with mismatched integer widths), so PETSc links
    # no ScaLAPACK at all and MatScaLAPACK is disabled.

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

    USE_HYPRE=0
    if [ "${1}" == "double" ] && [ "${2}" == "real" ] && [[ "${target}" != *-mingw* ]]; then
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
        MPI_FC=mpifort
        MPI_CXX=mpicxx
        export MPIF_FCLIBS='-lmpif -lmpi_abi'
    fi

    # triangle, tetgen
    USE_TRIANGLE=0
    USE_TETGEN=0
    if [ "${1}" == "double" ] ; then
         USE_TRIANGLE=1
         USE_TETGEN=1
    fi

    if [ ${USE_HYPRE} == 1 ]; then
        HYPRE_ARGS="--with-hypre=1 --with-hypre-include=${includedir} --with-hypre-lib=${libdir}/libHYPRE64.${dlext}"
    else
        HYPRE_ARGS="--with-hypre=0"
    fi

    if [ ${USE_MUMPS} == 1 ]; then
        MUMPS_ARGS="--with-mumps=1 --with-mumps-include=${includedir} --with-mumps-lib=[${libdir}/libdmumpspar.${dlext},${libdir}/libmumps_commonpar.${dlext},${libdir}/libpordpar.${dlext}]"
    else
        MUMPS_ARGS="--with-mumps=0"
    fi

    if [ ${USE_SUPERLU_DIST} == 1 ]; then
        SUPERLU_DIST_ARGS="--with-superlu_dist=1 --with-superlu_dist-include=${includedir} --with-superlu_dist-lib=${libdir}/libsuperlu_dist_Int64.${dlext}"
    else
        SUPERLU_DIST_ARGS="--with-superlu_dist=0"
    fi

    if [ ${USE_TETGEN} == 1 ]; then
        TETGEN_ARGS="--with-tetgen=1 --with-tetgen-include=${includedir} --with-tetgen-lib=${libdir}/libtet.${dlext}"
    else
        TETGEN_ARGS="--with-tetgen=0"
    fi

    if [ ${USE_TRIANGLE} == 1 ]; then
        TRIANGLE_ARGS="--with-triangle=1 --with-triangle-include=${includedir} --with-triangle-lib=${libdir}/libtriangle.${dlext}"
    else
        TRIANGLE_ARGS="--with-triangle=0"
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
        ${SUITESPARSE_ARGS} \
        ${SUPERLU_DIST_ARGS} \
        ${HYPRE_ARGS} \
        ${MUMPS_ARGS} \
        ${TETGEN_ARGS} \
        ${TRIANGLE_ARGS} \
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
               compat="5.11.0",
               platforms=filter(!Sys.iswindows, platforms)),
    # Stock 32-bit-integer MUMPS.  Its shared libraries privately link
    # SCALAPACK32_jll's libscalapack32 and call unsuffixed LP64 BLAS
    # through libblastrampoline.
    Dependency(PackageSpec(name="MUMPS_jll", uuid="ca64183c-ec4f-5579-95d5-17e128c21291");
               compat="5.8.4", platforms=filter(!Sys.iswindows, platforms)),
    # Fills libblastrampoline's LP64 forwarding slots at load time
    # (OpenBLAS32 >= 0.3.33 auto-forwards), needed by MUMPS internally.
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2");
               compat="0.3.33", platforms=filter(!Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="HYPRE64_jll"); compat="3.1.0",
               platforms=filter(!Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="SuperLU_DIST_jll"); compat="9.2.1",
               platforms=filter(!Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="TetGen_jll"); compat="1.6.0"),
    Dependency(PackageSpec(name="Triangle_jll"); compat="1.6.3"),
    # Julia's stdlib SuiteSparse (Int64 / SuiteSparse_long).  PETSc binds
    # these libraries by soname, so the build must match the SuiteSparse
    # shipped by the targeted Julia versions: 7.8.x (libcholmod.so.5) is
    # what Julia 1.12 ships.  Julia 1.10/1.11 ship 7.2.x/7.4.x with
    # libcholmod.so.4, which is soname-incompatible -- hence the
    # julia_compat = 1.12 below.  (Supporting several Julia minors at
    # once would need julia_version-expanded platforms.)
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"); compat="7.8.3"),
    Dependency("mpif_jll"; compat="0.1.5", platforms=filter(p -> p["mpi"] == "mpiabi", platforms)), # MPI Fortran bindings
]
append!(dependencies, platform_dependencies)

# Build the tarballs.
# NOTE: llvm16 seems to have an issue with PETSc 3.18.x as on apple architectures it doesn't know how to create dynamic libraries
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, clang_use_lld=false, julia_compat="1.12", preferred_gcc_version=v"9")
