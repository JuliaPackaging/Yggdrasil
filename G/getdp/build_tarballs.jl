using BinaryBuilder
using Base.BinaryPlatforms

name = "getdp"
version = v"3.5.0"

sources = [
    GitSource("https://gitlab.onelab.info/getdp/getdp.git",
              "864875cdfc652254f777311d58f510b38e508b56"),
    ArchiveSource("https://web.cels.anl.gov/projects/petsc/download/release-snapshots/petsc-3.20.6.tar.gz",
                  "20e6c260765f9593924bc5b1783bd152ec5c47246b47ce516cded7b505b34795"),
    ArchiveSource("https://mumps-solver.org/MUMPS_5.9.1.tar.gz",
                  "659c9b57646b5a003ac618baa1faf9dd2044e46c732b3daaccbc7158003e1b46"),
    ArchiveSource("https://gmsh.info/src/gmsh-4.10.5-source.tgz",
                  "cc030c5aee65e7d58f850b8b6f55a68945c89bc871f94e1239279f5a210fc4ea"),
    DirectorySource("./bundled"),
]

script = raw"""
# Keep all static dependencies outside the packaged prefix.
staging_prefix="${WORKSPACE}/getdp-deps"
mumps_prefix="${staging_prefix}/mumps"
petsc_prefix="${staging_prefix}/petsc"
gmsh_prefix="${staging_prefix}/gmsh"
mkdir -p "${mumps_prefix}/include/libseq" "${mumps_prefix}/lib" "${petsc_prefix}" "${gmsh_prefix}"

# P/PETSc/build_tarballs.jl:119-123,283-305,340-347.
pic_flags="-fPIC"
atomics_flags=""
petsc_cppflags="${CPPFLAGS}"
petsc_ldflags="-L${libdir}"
if [[ "${target}" == *-mingw* ]]; then
    pic_flags=""
    petsc_cppflags="${petsc_cppflags} -Dpetsc_EXPORTS"
    petsc_ldflags="${petsc_ldflags} -lssp"
elif [[ "${target}" == aarch64-*freebsd* ]]; then
    atomics_flags="-mno-outline-atomics"
fi

# 1. Sequential static MUMPS, with its bundled MPI replacement.
cd "${WORKSPACE}/srcdir/MUMPS_5.9.1"
cp Make.inc/Makefile.inc.generic.SEQ Makefile.inc

# M/MUMPS/MUMPS_seq@5/build_tarballs.jl:36-42; use the target FC.
mumps_fflags="${FFLAGS} ${pic_flags}"
: > empty.f
if ${FC} -c -fallow-argument-mismatch empty.f >/dev/null 2>&1; then
    mumps_fflags="${mumps_fflags} -fallow-argument-mismatch"
fi
rm -f empty.f empty.o

mumps_make_args=(
    CC="${CC}"
    FC="${FC}"
    FL="${FC}"
    AR="ar vr "
    RANLIB="ranlib"
    OPTC="-O3 ${CFLAGS} ${pic_flags}"
    OPTF="-O3 ${mumps_fflags}"
    OPTL="-O3 ${LDFLAGS}"
    CDEFS="-DAdd_"
    LMETISDIR="${libdir}"
    IMETIS="-I${includedir}"
    LMETIS="-L${libdir} -lmetis"
    ISCOTCH="-I${includedir}"
    LSCOTCH="-L${libdir} -lesmumps -lscotch -lscotcherr"
    ORDERINGSF="-Dpord -Dmetis -Dscotch"
    LIBBLAS="-L${libdir} -lopenblas"
    LAPACK="-L${libdir} -lopenblas"
)
# MUMPS src/Makefile:17 makes c a prerequisite of z (mixed precision);
# examples/Makefile:31 links zmumps, cmumps, then mumps_common.
make -j${nproc} z "${mumps_make_args[@]}"
cp include/*.h "${mumps_prefix}/include/"
cp libseq/*.h "${mumps_prefix}/include/libseq/"
cp lib/libzmumps.a lib/libcmumps.a lib/libmumps_common.a lib/libpord.a \
    libseq/libmpiseq.a "${mumps_prefix}/lib/"

# 2. Sequential, complex-double PETSc with 32-bit indices and static MUMPS.
cd "${WORKSPACE}/srcdir/petsc-3.20.6"
export PETSC_DIR="$(pwd)"
export PETSC_ARCH="${target}_double_complex_Int32"
export CMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}"
mumps_libs="[${mumps_prefix}/lib/libzmumps.a,${mumps_prefix}/lib/libcmumps.a,${mumps_prefix}/lib/libmumps_common.a,${mumps_prefix}/lib/libpord.a,${mumps_prefix}/lib/libmpiseq.a,${libdir}/libmetis.${dlext},${libdir}/libesmumps.${dlext},${libdir}/libscotch.${dlext},${libdir}/libscotcherr.${dlext},${libdir}/libopenblas.${dlext},-lpthread]"

# The live P/PETSc recipe has no per-target --known-* settings; its only
# --known-* option is the BLAS integer width (line 302), LP64 here.
# Its lines 315,318 also disable sowing and PETSc's pthread package.
./configure \
    --prefix="${petsc_prefix}/${PETSC_ARCH}" \
    --PETSC_ARCH="${PETSC_ARCH}" \
    --CC="${CC}" \
    --CXX="${CXX}" \
    --FC="${FC}" \
    --COPTFLAGS="-O3 -g" \
    --CXXOPTFLAGS="-O3 -g" \
    --FOPTFLAGS="-O3" \
    --CFLAGS="${pic_flags} -fno-stack-protector ${atomics_flags}" \
    --CXXFLAGS="${pic_flags} -fno-stack-protector ${atomics_flags}" \
    --CPPFLAGS="${petsc_cppflags}" \
    --FFLAGS="${pic_flags} -ffree-line-length-999" \
    --LDFLAGS="${petsc_ldflags}" \
    --with-mpi=0 \
    --with-scalar-type=complex \
    --with-precision=double \
    --with-64-bit-indices=0 \
    --with-shared-libraries=0 \
    --with-debugging=0 \
    --with-fortran-bindings=0 \
    --with-x=0 \
    --with-batch \
    --with-pthread=0 \
    --with-sowing=0 \
    --with-mumps=1 \
    --with-mumps-serial=1 \
    --with-mumps-include="${mumps_prefix}/include" \
    --with-mumps-lib="${mumps_libs}" \
    --with-blaslapack-lib="${libdir}/libopenblas.${dlext}" \
    --known-64-bit-blas-indices=0
make -j${nproc}
make install

# GetDP CMakeLists.txt:421-424,435-466 reads this installed architecture's
# petscvariables, includes and libpetsc.a; 510-515 reads its full link closure.
export PETSC_DIR="${petsc_prefix}"

# 3. Static Gmsh with the private API used by GetDP.
cd "${WORKSPACE}/srcdir/gmsh-4.10.5-source"
mkdir build
cd build
# POST: Pos_Format.cpp:1729-1746 stores PViewData{List,GModel}; F_Gmsh.cpp
# searches those fields through PViewData::searchVector and OctreePost.
# PARSER: GmshRead/GmshMerge call GmshMergePostProcessingFile/GmshMergeFile
# (SolvingOperations.cpp:2438,2469), including parsed .pos files.
# ONELAB: Message.cpp:753-755,769 uses the server supplied by GmshMessage.cpp:83.
# EIGEN: BF_Node.cpp:194 and Pos_Element.cpp:573 call BasisFactory;
# polynomialBasis.cpp:46 inverts its Vandermonde matrix through fullMatrix.
# Geometry/numeric code, MSH 4.1 I/O and mesh getNodes/getElements are built
# unconditionally (Gmsh CMakeLists.txt:576-578; src/geo/CMakeLists.txt).
# MESH is the mesh generator, not mesh I/O; ANN is unnecessary for OctreePost.
# With FLTK/GRAPHICS, MED/CGNS and ZIPPER disabled, none of the zlib discovery
# paths is reached (Gmsh CMakeLists.txt:683-699,995-1030,1349-1365).
# BinaryBuilder's toolchain reads ENV{prefix} for CMAKE_INSTALL_PREFIX
# (BinaryBuilderBase/BuildToolchains.jl:106); scope it to this CMake invocation.
prefix="${gmsh_prefix}" cmake .. \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_INSTALL_PREFIX="${gmsh_prefix}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_INCLUDEDIR=include \
    -DCMAKE_BUILD_TYPE=Release \
    -DGMSH_RELEASE=1 \
    -DDEFAULT=0 \
    -DENABLE_BUILD_LIB=1 \
    -DENABLE_PRIVATE_API=1 \
    -DENABLE_POST=1 \
    -DENABLE_PARSER=1 \
    -DENABLE_ONELAB=1 \
    -DENABLE_EIGEN=1 \
    -DENABLE_GMP=0 \
    -DENABLE_MESH=0 \
    -DENABLE_ANN=0 \
    -DENABLE_PLUGINS=0 \
    -DENABLE_OPENMP=0 \
    -DENABLE_FLTK=0 \
    -DENABLE_GRAPHICS=0 \
    -DENABLE_OCC=0 \
    -DENABLE_MED=0 \
    -DENABLE_CGNS=0 \
    -DENABLE_ZIPPER=0 \
    -DENABLE_TESTS=0
make -j${nproc} lib
# Gmsh CMakeLists.txt:1883-1903 explicitly supports install/fast after make lib:
# install libgmsh.a, gmsh.h, private headers and the bundled Eigen headers,
# without building the optional gmsh executable.
make install/fast
# This configuration's remaining external libraries are platform system libs:
# dl on Linux (Gmsh CMakeLists.txt:1438-1441) is in PETSc's link closure;
# Windows winmm/wsock32/ws2_32/psapi are also added by GetDP at lines 684-686.

# 4. GetDP executable; all three static dependencies remain in staging.
cd "${WORKSPACE}/srcdir/getdp"
if [[ "${target}" == *-mingw* ]]; then
    # GetDP CMakeLists.txt:857 forces -static, incompatible with JLL DLLs;
    # OpenBLAS32, METIS and SCOTCH require dynamic linking.
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/mingw-dynamic-dependencies.patch"
fi
mkdir build
cd build
# GMSH_LIB/GMSH_INC: GetDP CMakeLists.txt:383-392; the archive is linked before
# PETSc and its external/system libraries. No gmsh_jll is used.
# BLAS_LAPACK_LIBRARIES: GetDP CMakeLists.txt:247-251.
getdp_linker_flags=""
if [[ "${target}" == aarch64-apple-* ]]; then
    # PETSc's complex division needs __divdc3 from LLVM compiler-rt.
    getdp_linker_flags="-L${libdir}/darwin -lclang_rt.osx"
fi
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_INSTALL_PREFIX="${prefix}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_EXE_LINKER_FLAGS="${getdp_linker_flags}" \
    -DDEFAULT=0 \
    -DENABLE_KERNEL=1 \
    -DENABLE_PETSC=1 \
    -DPETSC_DIR="${PETSC_DIR}" \
    -DPETSC_ARCH="${PETSC_ARCH}" \
    -DENABLE_GMSH=1 \
    -DGMSH_LIB="${gmsh_prefix}/lib/libgmsh.a" \
    -DGMSH_INC="${gmsh_prefix}/include" \
    -DENABLE_BLAS_LAPACK=1 \
    -DBLAS_LAPACK_LIBRARIES="${libdir}/libopenblas.${dlext}" \
    -DENABLE_NR=1 \
    -DENABLE_GSL=0 \
    -DENABLE_PYTHON=0 \
    -DENABLE_SLEPC=0 \
    -DENABLE_ARPACK=0 \
    -DENABLE_SPARSKIT=0 \
    -DENABLE_PEWE=0 \
    -DENABLE_MMA=0 \
    -DENABLE_MPI=0 \
    -DENABLE_FORTRAN=0 \
    -DENABLE_OPENMP=0
make -j${nproc}
install -Dvm 755 "getdp${exeext}" "${bindir}/getdp${exeext}"
install_license ../LICENSE.txt
rm -rf "${staging_prefix}"
"""

platforms = supported_platforms()
filter!(p -> nbits(p) != 32, platforms)
# Both FreeBSD architectures are present in all three numerical dependency Artifacts.toml
# files. Keep them, as well as x86_64-w64-mingw32.
# Expansion order follows P/PETSc/build_tarballs.jl:459-464.
platforms = expand_gfortran_versions(platforms)
platforms = expand_cxxstring_abis(platforms)

products = [ExecutableProduct("getdp", :getdp)]

dependencies = [
    Dependency("OpenBLAS32_jll"; compat="0.3.33"),
    Dependency("METIS_jll"),
    Dependency("SCOTCH_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    BuildDependency("LLVMCompilerRT_jll"; platforms=filter(Sys.isapple, platforms)),
]

# SCOTCH uses GCC 9.1.0 (S_SCOTCH_build_tarballs.jl:145).
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9.1.0", clang_use_lld=false)
