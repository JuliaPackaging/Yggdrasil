using BinaryBuilder
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SCALAPACK"
version = v"2.2.0"
scalapack_version = v"2.2.0"

sources = [
  ArchiveSource("http://www.netlib.org/scalapack/scalapack-$(scalapack_version).tgz",
                "40b9406c20735a9a3009d863318cb8d3e496fb073d201c5463df810e01ab2a57"),
  DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/scalapack-*

# the patch prevents running foreign executables, which fails on most platforms
# we instead set CDEFS manually below
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
  atomic_patch -p1 ${f}
done

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix}
             -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}"
             -DCMAKE_BUILD_TYPE=Release
             -DBUILD_SHARED_LIBS=ON)

# if [[ "${target}" == i686-*  ]] || [[ "${target}" == x86_64-*  ]]; then
#   CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-lgfortran -lquadmath")
# else
#   if [[ "${target}" == powerpc64le-linux-gnu ]]; then
#     # special case for CMake to discover MPI_Fortran
#     CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-lgfortran -L/opt/${target}/${target}/sys-root/usr/lib64 -lpthread -lrt" \
#                   -DCMAKE_SHARED_LINKER_FLAGS="-lgfortran -L/opt/${target}/${target}/sys-root/usr/lib64 -lpthread -lrt" \
#                   -DMPI_Fortran_LINK_FLAGS="-Wl,-rpath -Wl,/workspace/destdir/lib -Wl,--enable-new-dtags -L/workspace/destdir/lib -Wl,-L/opt/${target}/${target}/sys-root/usr/lib64 -Wl,-lpthread -Wl,-lrt")
#   else
#     CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-lgfortran")
#   fi
# fi
# CMAKE_FLAGS+=(-DMPI_BASE_DIR=${prefix})

OPENBLAS=(-lopenblas)
CPPFLAGS=()
FFLAGS=(-cpp -ffixed-line-length-none)

# TODO: Follow the official instruction to build in ILP64 mode; see <https://github.com/Reference-ScaLAPACK/scalapack/pull/19>
if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
  OPENBLAS=(-lopenblas64_)
  if [[ "${target}" == powerpc64le-linux-gnu ]]; then
    OPENBLAS+=(-lgomp)
  fi
  syms=(caxpy cbdsqr ccopy cdotc cdotu cgbmv cgbtrf cgemm cgemv cgerc cgeru cgesv cgetrf cgetrs chbmv chemm chemv cher cher2 cher2k cherk chetrd clacgv clacpy cladiv clanhs clarfg clartg claset clasr classq claswp cpbtrf cpotrf cpttrf crot csbmv cscal csscal cswap csymm csyr2k csyrk ctbtrs ctrmm ctrmv ctrsm ctrsv ctrtrs dasum daxpy dbdsqr dcopy ddot dgbmv dgbtrf dgemm dgemv dger dgesv dgetrf dgetrs dhbmv disnan dlabad dlacpy dlae2 dlaebz dlaed4 dlaev2 dlagtf dlagts dlahqr dlamc3 dlamch dlange dlanst dlanv2 dlapy2 dlapy3 dlaqr0 dlaqr1 dlaqr3 dlaqr4 dlarfg dlarfx dlarnv dlarra dlarrb dlarrc dlarrd dlarrk dlarrv dlartg dlaruv dlascl dlaset dlasq2 dlasr dlasrt dlassq dlaswp dlasy2 dnrm2 dpbtrf dpotrf dpttrf drot dsbmv dscal dstedc dsteqr dsterf dswap dsymm dsymv dsyr dsyr2 dsyr2k dsyrk dsytrd dtbtrs dtrmm dtrmv dtrsm dtrsv dtrtrs dzasum dznrm2 dzsum1 icamax icmax1 idamax ieeeck ilaenv isamax izamax izmax1 lsame lsamen sasum saxpy sbdsqr scasum scnrm2 scopy scsum1 sdot sgbmv sgbtrf sgemm sgemv sger sgesv sgetrf sgetrs shbmv sisnan slabad slacpy slae2 slaebz slaed4 slaev2 slagtf slagts slahqr slamc3 slamch slange slanst slanv2 slapy2 slapy3 slaqr0 slaqr1 slaqr3 slaqr4 slarfg slarfx slarnv slarra slarrb slarrc slarrd slarrk slarrv slartg slaruv slascl slaset slasq2 slasr slasrt slassq slaswp slasy2 snrm2 spbtrf spotrf spttrf srot ssbmv sscal sstedc ssteqr ssterf sswap ssymm ssymv ssyr ssyr2 ssyr2k ssyrk ssytrd stbtrs strmm strmv strsm strsv strtrs xerbla zaxpy zbdsqr zcopy zdbmv zdotc zdotu zdscal zgbmv zgbtrf zgemm zgemv zgerc zgeru zgesv zgetrf zgetrs zhbmv zhemm zhemv zher zher2 zher2k zherk zhetrd zlacgv zlacpy zladiv zlanhs zlarfg zlartg zlaset zlasr zlassq zlaswp zpbtrf zpotrf zpttrf zrot zscal zswap zsymm zsyr2k zsyrk ztbtrs ztrmm ztrmv ztrsm ztrsv ztrtrs)
  for sym in ${syms[@]}
  do
    CPPFLAGS+=("-D${sym}=${sym}_64")
    CPPFLAGS+=("-D${sym}_=${sym}_64_")  # due to some evil #defines in SCALAPACK
    CPPFLAGS+=("-D${sym^^}=${sym}_64")
  done

  CMAKE_FLAGS+=(-DCMAKE_Fortran_FLAGS=\"${CPPFLAGS[*]} ${FFLAGS[*]}\" \
                -DCMAKE_C_FLAGS=\"${CPPFLAGS[*]}\")
fi

# We attach our MPI flags here
CMAKE_FLAGS+=(-DBLAS_LIBRARIES=\"${OPENBLAS[*]} -lmpifort -lmpi\" \
              -DLAPACK_LIBRARIES=\"${OPENBLAS[*]}\")

export CDEFS="Add_"

mkdir build && cd build
cmake .. "${CMAKE_FLAGS[@]}"

make -j${nproc} all
make install
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# # OpenMPI and MPICH are not precompiled for Windows
# # Can't get the code to build for PowerPC with libgfortran3
# platforms = expand_gfortran_versions(filter!(p -> !Sys.iswindows(p) && arch(p) != "powerpc64le", supported_platforms()))

platforms = expand_gfortran_versions(supported_platforms())

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libscalapack", :libscalapack),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS_jll"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6")
