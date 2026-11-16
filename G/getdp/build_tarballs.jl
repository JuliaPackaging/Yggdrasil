using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = joinpath(@__DIR__, "../..")
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "getdp"
# Upstream GetDP has no release after 3.5.0; the pinned commit below is
# getdp_4_0_0_rc1-104-g065ad5d0 (its CMakeLists.txt already reads the unreleased 4.0.0).
# v3.5.1 marks "after 3.5.0, before upstream's next release" and cannot collide with it.
version = v"3.5.1"

sources = [
    GitSource("https://gitlab.onelab.info/getdp/getdp.git",
              "065ad5d0a5c324d6e1c3517978066a3fa487e0bf"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/getdp
mpi_options=(-DMPI_HOME=${prefix})
# GetDP's PETSc code calls MPI even when FindMPI cannot validate the cross-built libraries.
mpi_lib=${libdir}/libmpi.${dlext}
LBT=blastrampoline
gmsh_lib=${libdir}/libgmsh.${dlext}
if [[ ${target} == *-mingw* ]]; then
    # Upstream forces -static, which prevents linking the JLL DLLs.
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-dynamic-dependencies.patch
    LBT=blastrampoline-5
    gmsh_lib=${libdir}/gmsh.${dlext}
    mpi_lib=${libdir}/msmpi.${dlext}
    mpi_options+=(-DMPI_GUESS_LIBRARY_NAME=MSMPI -DMPI_C_LIBRARIES=${mpi_lib} -DMPI_CXX_LIBRARIES=${mpi_lib})
fi
if [[ ${bb_full_target} == *mpiabi* ]]; then
    mpi_lib=${libdir}/libmpi_abi.${dlext}
elif [[ ${bb_full_target} == *mpitrampoline* ]]; then
    mpi_lib=${libdir}/libmpitrampoline.${dlext}
    export MPITRAMPOLINE_CC=${CC} MPITRAMPOLINE_CXX=${CXX} MPITRAMPOLINE_FC=${FC}
fi

# Explicit installed paths bypass petscvariables, whose flags belong to PETSc's build.
unset PETSC_DIR PETSC_ARCH
petsc_prefix=${libdir}/petsc/double_complex_Int32
# GetDP master and Gmsh 4.15 have different ONELAB class layouts; keep their inline symbols local.
cmake -B build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS} -fvisibility=hidden -fvisibility-inlines-hidden" \
    -DDEFAULT=0 \
    -DENABLE_KERNEL=1 \
    -DENABLE_PETSC=1 \
    -DEXTERNAL_LIBRARIES=${mpi_lib} \
    -DPETSC_LIBS=${petsc_prefix}/lib/libpetsc_double_complex_Int32.${dlext} \
    -DPETSC_INC=${petsc_prefix}/include \
    -DENABLE_GMSH=1 \
    -DGMSH_LIB=${gmsh_lib} \
    -DGMSH_INC=${includedir} \
    -DENABLE_BLAS_LAPACK=1 \
    -DBLAS_LAPACK_LIBRARIES=${libdir}/lib${LBT}.${dlext} \
    -DENABLE_NR=1 \
    -DENABLE_GSL=0 \
    -DENABLE_PYTHON=0 \
    -DENABLE_SLEPC=0 \
    -DENABLE_ARPACK=0 \
    -DENABLE_SPARSKIT=0 \
    -DENABLE_PEWE=0 \
    -DENABLE_MMA=0 \
    -DENABLE_MPI=1 \
    "${mpi_options[@]}" \
    -DENABLE_FORTRAN=0 \
    -DENABLE_OPENMP=0
cmake --build build --parallel ${nproc}
install -Dvm 755 build/getdp${exeext} ${bindir}/getdp${exeext}
install_license LICENSE.txt
"""

platforms = supported_platforms()
# PETSc's ILP64 BLAS dependency is available only on 64-bit targets.
filter!(p -> nbits(p) == 64, platforms)
platforms = expand_gfortran_versions(platforms)
platforms = expand_cxxstring_abis(platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

products = [ExecutableProduct("getdp", :getdp)]

dependencies = [
    # PETSc_jll 3.25.6 has MUMPS in its complex variants from its build of #15594 on.
    Dependency("PETSc_jll"; compat="3.25.6"),
    # 4.15.4 is the first gmsh_jll with the private API that GetDP includes.
    Dependency("gmsh_jll"; compat="4.15.4"),
    # Zlib_jll 1.4 tags its FreeBSD artifacts os_version 14.1, which the x86_64 FreeBSD 13.4
    # build environment does not match, as in P/PETSc/common.jl.
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"); compat="1.3.1"),
    Dependency("libblastrampoline_jll"; compat="5.11.2"),
    Dependency("CompilerSupportLibraries_jll"; compat="1.2.0"),
]
append!(dependencies, platform_dependencies)

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.12", preferred_gcc_version=v"9", clang_use_lld=false)
