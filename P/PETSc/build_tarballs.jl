# PETSc 3.21.4 with OpenBLAS and static compilations of SuperLU_Dist, SuiteSparse and MUMPS, triangle and TETGEN on machines that support it
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "PETSc"
version = v"3.21.5"
petsc_version = v"3.21.5"

MPItrampoline_compat_version="5.5.0"
MicrosoftMPI_compat_version="~10.1.4" 
MPICH_compat_version="~4.1.2"    

# Collection of sources required to build PETSc. Avoid using the git repository, it will
# require building SOWING which fails in all non-linux platforms.
sources = [
    ArchiveSource("https://web.cels.anl.gov/projects/petsc/download/release-snapshots/petsc-$(petsc_version).tar.gz",
                  "4eb1ec04c1a8988bd524f71f8d7d980dc1853d5be8791c0f19f3c09eef71fdd2"),
    DirectorySource("./bundled"),
]


# Bash recipe for building across all platforms
script = raw"""

# so we can use a newer version of cmake
apk del cmake

cd $WORKSPACE/srcdir/petsc*
atomic_patch -p1 $WORKSPACE/srcdir/patches/petsc_name_mangle.patch

# TODO: MPITrampoline embeds the wrong CC. https://github.com/JuliaPackaging/Yggdrasil/issues/7420
export MPITRAMPOLINE_CC="$(which $CC)"
export MPITRAMPOLINE_CXX="$(which $CXX)"
export MPITRAMPOLINE_FC="$(which $FC)"

if [[ "${target}" == *-mingw* ]]; then
    # On windows, it compiles fine but we obtain a following runtime error:
    # 
    # Mingw-w64 runtime failure:
    # 32 bit pseudo relocation at 00000000093934AA out of range, targeting 00007FF8B7756530, yielding the value 00007FF8AE3C3082.
    #
    # (see https://github.com/boriskaus/test_PETSc_jll/actions/runs/7444842322/job/20251986258#step:7:236)
    #
    # Interestingly, this error does NOT occur if we use the originally compiled PETSc_jll version 3.18.6 from May 2023.
    # (e.g., https://github.com/boriskaus/test_PETSc_jll/actions/runs/7444942534/job/20252261704#step:6:49). 
    #
    # If we recompile it using the same versions of all packages (while fixing llvm to version 13, as was used in May 2023 for compilation), we have the runtime error above
    #
    # The same issue occured in HDF5_jll (https://github.com/eschnett/Yggdrasil/pull/6)
    #
    # Interestingly, SuperLU_Dist_jll does not have this issue and runs fine in serial & parallel on windows 
    # (see e.g. https://github.com/boriskaus/test_SuperLU_DIST_jll/actions/runs/7595261750/job/20687625690#step:7:181)
    #
    # Despite a significant time-effort from my side, I have been unable to fix the issue, so I deactivate MPI on windows as a workaround.
    #MPI_LIBS=--with-mpi-lib="${libdir}/msmpi.${dlext}"
    #MPI_INC=--with-mpi-include=${includedir}

    MPI_FFLAGS=""
    MPI_LIBS=""
    MPI_INC=""
    USE_MPI=0

else
    if grep -q MPICH_NAME $prefix/include/mpi.h; then
        USE_MPI=1
        MPI_FFLAGS=""
        MPI_LIBS=--with-mpi-lib="[${libdir}/libmpifort.${dlext},${libdir}/libmpi.${dlext}]"
        MPI_INC=--with-mpi-include=${includedir}
    elif grep -q MPItrampoline $prefix/include/mpi.h; then
        USE_MPI=1
        MPI_FFLAGS="-fcray-pointer"
        MPI_LIBS=--with-mpi-lib="[${libdir}/libmpitrampoline.${dlext}]"
        MPI_INC=--with-mpi-include=${includedir}
    elif grep -q OMPI_MAJOR_VERSION $prefix/include/mpi.h; then
        USE_MPI=1
        MPI_FFLAGS=""
        MPI_LIBS=--with-mpi-lib="[${libdir}/libmpi_usempif08.${dlext},${libdir}/libmpi_usempi_ignore_tkr.${dlext},${libdir}/libmpi_mpifh.${dlext},${libdir}/libmpi.${dlext}]"
        MPI_INC=--with-mpi-include=${includedir}
    else
        USE_MPI=0
        MPI_FFLAGS=""
        MPI_LIBS=""
        MPI_INC=""
    fi

fi

atomic_patch -p1 $WORKSPACE/srcdir/patches/mingw-version.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/mpi-constants.patch     
atomic_patch -p1 $WORKSPACE/srcdir/patches/sosuffix.patch

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
    if [ "${1}" == "double" ] &&  [ "${3}" == "Int64" ]; then
        USE_SUPERLU_DIST=1    
    fi
    if [[ "${target}" == *-mingw* ]]; then
        USE_SUPERLU_DIST=0
    fi

    # install suitesparse if available - note that this shipped with julia and therefore linked to specific julia versions
    USE_SUITESPARSE=0
    if [ "${1}" == "double" ]; then
        USE_SUITESPARSE=1    
    fi
    if [[ "${target}" == *-mingw* ]]; then
        USE_SUITESPARSE=0
    fi

    # See if we can install MUMPS
    USE_STATIC_MUMPS=0  
    if [[ "${target}" == *-mingw* ]]; then
        # try static
        USE_STATIC_MUMPS=0
    elif [ "${1}" == "double" ] && [ "${2}" == "real" ]; then 
        USE_STATIC_MUMPS=1      
    else
        USE_STATIC_MUMPS=0      
    fi
    if [[ "${target}" == powerpc64le-linux-* ]] || [[ "${target}" == aarch64-linux-* ]] || [[ "${target}" == arm-linux-* ]]; then        
        USE_STATIC_MUMPS=0
    fi

    LIBFLAGS="-L${libdir}" 
    if [[ "${target}" == *-mingw* ]]; then
        LIBFLAGS="-L${libdir} -lssp -lmsmpi" 
    fi

    # use LBT - to be activated @ a later stage
    #if [[ "${target}" == aarch64-apple-* ]]; then    
    #    LIBFLAGS="-L${libdir}" 
    #    # Linking requires the function `__divdc3`, which is implemented in
    #    # `libclang_rt.osx.a` from LLVM compiler-rt.
    #    BLAS_LAPACK_LIB="${libdir}/libblastrampoline.${dlext}"
    #    CLINK_FLAGS="-L${libdir}/darwin -lclang_rt.osx"
    #elif [[ "${target}" == *-mingw* ]]; then
    #    # BLAS_LAPACK_LIB="${libdir}/libblastrampoline-5.${dlext}"
    #    BLAS_LAPACK_LIB="${libdir}/libopenblas.${dlext}"            # LBT doesn't seem to work on windows
    #    CLINK_FLAGS=""
    #else
    #    BLAS_LAPACK_LIB="${libdir}/libblastrampoline.${dlext}"
    #    CLINK_FLAGS=""
    #fi

    BLAS_LAPACK_LIB="${libdir}/libopenblas.${dlext}"

    if  [ ${DEBUG_FLAG} == 1 ]; then
        _COPTFLAGS='-O0 -g'
        _CXXOPTFLAGS='-O0 -g'
        _FOPTFLAGS='-O0' 
    else
        _COPTFLAGS='-O3 -g'
        _CXXOPTFLAGS='-O3 -g'
        _FOPTFLAGS='-O3' 
    fi

    MPI_CC=mpicc
    MPI_FC=mpif90
    MPI_CXX=mpicxx
    if [ -f "${libdir}/libmpitrampoline.${dlext}" ]; then
        # required for mpitrampoline
        MPI_FC=mpifc
    elif [ -d "${libdir}/openmpi" ]; then
        # SuperLU_DIST and MUMPS cannot be compiled statically with OpenMPI, it seems. As this appears to be a less common platform,
        # and we should in principle be able to use ith thorugh MPItrampoline, the external packages are commented out
        MPI_CC=${CC}
        MPI_FC=${FC}
        MPI_CXX=${CXX}
        USE_SUPERLU_DIST=0
        USE_STATIC_MUMPS=1
    elif [[ "${target}" == *-mingw* ]]; then
        # since we don't use MPI on windows
        MPI_CC=${CC}
        MPI_FC=${FC}
        MPI_CXX=${CXX}
        USE_SUPERLU_DIST=0
        USE_SUITESPARSE=0
    fi
    if [[ "${target}" == powerpc64le-linux-* ]] || [[ "${target}" == aarch64-linux-* ]] || [[ "${target}" == arm-linux-* ]]; then        
        USE_STATIC_MUMPS=0
    fi

    # triangle & tetgen
    USE_TRIANGLE=0
    USE_TETGEN=0
    if [ "${1}" == "double" ] ; then
         USE_TRIANGLE=1
         USE_TETGEN=1
    fi
 
    echo "USE_SUPERLU_DIST="$USE_SUPERLU_DIST
    echo "USE_SUITESPARSE="$USE_SUITESPARSE
    echo "USE_MUMPS="$USE_STATIC_MUMPS
    echo "USE_TETGEN="$USE_TETGEN
    echo "USE_TRIANGLE="$USE_TRIANGLE
    echo "1="${1}
    echo "2="${2}
    echo "3="${3}
    echo "4="${4}
    echo "USE_INT64"=$USE_INT64
    echo "Machine_name="$Machine_name
    echo "LIBFLAGS="$LIBFLAGS
    echo "target="$target
    echo "DEBUG="${DEBUG_FLAG}
    echo "COPTFLAGS="${_COPTFLAGS}
    echo "BLAS_LAPACK_LIB="$BLAS_LAPACK_LIB
    echo "prefix="${libdir}/petsc/${PETSC_CONFIG}
    echo "MPI_CC="$MPI_CC
    echo "MPI_FC="$MPI_FC
    echo "MPI_CXX="$MPI_CXX
    
    mkdir $libdir/petsc/${PETSC_CONFIG}
        
   
    # Step 1: build static libraries of external packages (happens during configure)    
    # Note that mpicc etc. should be indicated rather than ${CC} to compile external packages 
    ./configure --prefix=${libdir}/petsc/${PETSC_CONFIG} \
        --CC=${MPI_CC} \
        --FC=${MPI_FC} \
        --CXX=${MPI_CXX} \
        --COPTFLAGS=${_COPTFLAGS} \
        --CXXOPTFLAGS=${_CXXOPTFLAGS} \
        --FOPTFLAGS=${_FOPTFLAGS}  \
        --with-blaslapack-lib=${BLAS_LAPACK_LIB}  \
        --with-blaslapack-suffix="" \
        --CFLAGS='-fno-stack-protector '  \
        --FFLAGS="${MPI_FFLAGS} ${FFLAGS[*]}"  \
        --LDFLAGS="${LIBFLAGS}"  \
        --CC_LINKER_FLAGS="${CLINK_FLAGS}" \
        --with-64-bit-indices=${USE_INT64}  \
        --with-debugging=${DEBUG_FLAG}  \
        --with-batch \
        --with-mpi=${USE_MPI} \
        ${MPI_LIBS} \
        ${MPI_INC} \
        --with-sowing=0 \
        --with-precision=${1}  \
        --with-scalar-type=${2} \
        --with-pthread=0 \
        --PETSC_ARCH=${target}_${PETSC_CONFIG} \
        --with-scalapack-lib=${libdir}/libscalapack32.${dlext} \
        --with-scalapack-include=${includedir} \
        --download-suitesparse=${USE_SUITESPARSE} \
        --download-suitesparse-shared=0 \
        --download-superlu_dist=${USE_SUPERLU_DIST} \
        --download-superlu_dist-shared=0 \
        --download-mumps=${USE_STATIC_MUMPS} \
        --download-mumps-shared=0 \
        --download-tetgen=${USE_TETGEN} \
        --download-triangle=${USE_TRIANGLE} \
        --SOSUFFIX=${PETSC_CONFIG} \
        --with-shared-libraries=1 \
        --with-clean=1

    if [[ "${target}" == *-mingw* ]]; then
        export CPPFLAGS="-Dpetsc_EXPORTS"
    elif [[ "${target}" == powerpc64le-* ]]; then
        export CFLAGS="-fPIC"
        export FFLAGS="-fPIC"
    fi

    make -j${nproc} \
        CPPFLAGS="${CPPFLAGS}" \
        CFLAGS="${CFLAGS}" \
        FFLAGS="${FFLAGS}"
    make install

    # Remove PETSc.pc because petsc.pc also exists, causing conflicts on case-insensitive file-systems.
    rm ${libdir}/petsc/${PETSC_CONFIG}/lib/pkgconfig/PETSc.pc
    # sed -i -e "s/-lpetsc/-lpetsc_${PETSC_CONFIG}/g" "$libdir/petsc/${PETSC_CONFIG}/lib/pkgconfig/petsc.pc"
    # cp $libdir/petsc/${PETSC_CONFIG}/lib/pkgconfig/petsc.pc ${prefix}/lib/pkgconfig/petsc_${PETSC_CONFIG}.pc

    if  [ "${1}" == "double" ] &&  [ "${2}" == "real" ] &&  [ "${3}" == "Int64" ] &&  [ "${4}" == "opt" ]; then
        
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

    if  [ "${1}" == "double" ] &&  [ "${2}" == "real" ] &&  [ "${3}" == "Int64" ] &&  [ "${4}" == "deb" ]; then
        
        # this is the example that PETSc uses to test the correct installation        
        # We compile it witn debug flags (helpful to catch issues)
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

build_petsc double real Int64 opt
build_petsc double real Int64 deb       # compile at least one debug version
#build_petsc double real Int32 opt
#build_petsc single real Int32 opt
#build_petsc double complex Int32 opt
#build_petsc single complex Int32 opt
#build_petsc single real Int64 opt
#build_petsc double complex Int64 opt
#build_petsc single complex Int64 opt
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# We attempt to build for all defined platforms
platforms = expand_gfortran_versions(supported_platforms(exclude=[Platform("i686", "windows"),
                                                                  Platform("i686","linux"; libc="musl"),
                                                                  Platform("i686","linux"; libc="gnu"),
                                                                  Platform("x86_64","freebsd"),
                                                                  Platform("armv6l","linux"; libc="musl"),
                                                                  Platform("armv7l","linux"; libc="musl"),
                                                                  Platform("armv7l","linux"; libc="gnu"),
                                                                  Platform("aarch64","linux"; libc="musl")]))

# a few, but not all, platforms with libgfortran 3.0.0 are excluded
platforms, platform_dependencies = MPI.augment_platforms(platforms; 
                                        MPItrampoline_compat = MPItrampoline_compat_version,
                                        MPICH_compat         = MPICH_compat_version,
                                        MicrosoftMPI_compat  = MicrosoftMPI_compat_version )

# mpitrampoline and libgfortran 3 don't seem to work
platforms = filter(p -> !(libgfortran_version(p) == v"3" && p.tags["mpi"]=="mpitrampoline"), platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv7l" && libc(p) == "glibc"), platforms)
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "x86_64" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "i686"), platforms)

# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
#platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

products = [
    ExecutableProduct("ex4", :ex4)
    ExecutableProduct("ex42", :ex42)
    ExecutableProduct("ex19", :ex19)
    ExecutableProduct("ex19_int64_deb", :ex19_int64_deb)

    # Current default build, equivalent to Float64_Real_Int32
    LibraryProduct("libpetsc_double_real_Int64", :libpetsc, "\$libdir/petsc/double_real_Int64/lib")
    LibraryProduct("libpetsc_double_real_Int64", :libpetsc_Float64_Real_Int64, "\$libdir/petsc/double_real_Int64/lib")
    LibraryProduct("libpetsc_double_real_Int64_deb", :libpetsc_Float64_Real_Int64_deb, "\$libdir/petsc/double_real_Int64_deb/lib")
    #LibraryProduct("libpetsc_double_real_Int32", :libpetsc_Float64_Real_Int32, "\$libdir/petsc/double_real_Int32/lib")
    #LibraryProduct("libpetsc_single_real_Int32", :libpetsc_Float32_Real_Int32, "\$libdir/petsc/single_real_Int32/lib")
    #LibraryProduct("libpetsc_double_complex_Int32", :libpetsc_Float64_Complex_Int32, "\$libdir/petsc/double_complex_Int32/lib")
    #LibraryProduct("libpetsc_single_complex_Int32", :libpetsc_Float32_Complex_Int32, "\$libdir/petsc/single_complex_Int32/lib")
    #LibraryProduct("libpetsc_single_real_Int64", :libpetsc_Float32_Real_Int64, "\$libdir/petsc/single_real_Int64/lib")
    #LibraryProduct("libpetsc_double_complex_Int64", :libpetsc_Float64_Complex_Int64, "\$libdir/petsc/double_complex_Int64/lib")
    #LibraryProduct("libpetsc_single_complex_Int64", :libpetsc_Float32_Complex_Int64, "\$libdir/petsc/single_complex_Int64/lib")
]

dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency(PackageSpec(name="SCALAPACK32_jll")),
    
    BuildDependency("LLVMCompilerRT_jll"; platforms=[Platform("aarch64", "macos")]),
    Dependency("CompilerSupportLibraries_jll"),

    HostBuildDependency(PackageSpec(; name="CMake_jll"))
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs.
# NOTE: llvm16 seems to have an issue with PETSc 3.18.x as on apple architectures it doesn't know how to create dynamic libraries  
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, 
               julia_compat="1.9", 
               preferred_gcc_version = v"9",
               clang_use_lld=false)
