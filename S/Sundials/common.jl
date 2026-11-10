using BinaryBuilder
using BinaryBuilderBase
using Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

const version = v"7.9.0"

# Collection of sources required to build Sundials
function get_sources()
    return [
        GitSource("https://github.com/LLNL/sundials.git", "312fc0f3684f27209ca9dc9249d194436eb41a7a";
                  tag="v$(version)"),
        DirectorySource("./bundled"),
    ]
end

get_platforms() = supported_platforms()

function get_dependencies()
    dependencies = [
        HostBuildDependency("CMake_jll"),
        # 5.8.0 is what Julia 1.10 ships, but it lacks aarch64-freebsd and riscv64; every 5.x
        # provides the same libblastrampoline.so.5.
        Dependency("libblastrampoline_jll", v"5.11.2"; compat="5.8.0"),
        # KLU uses no BLAS, so it comes from Julia's own SuiteSparse, which ships libklu 2 from
        # Julia 1.10 (SuiteSparse 7.2.1) on. SuiteSparse32_jll 7, the only SuiteSparse32 release
        # with libklu 2, requires Julia 1.11. 7.2.1 lacks aarch64-freebsd and riscv64, so the
        # build uses 7.14.0, whose KLU structs match 7.2.1.
        Dependency("SuiteSparse_jll", v"7.14.0"; compat="7.2.1"),
    ]
    return dependencies
end

# products we'll build (common to both CPU and GPU versions)
function get_products()
    products = [
        LibraryProduct("libsundials_arkode", :libsundials_arkode),
        LibraryProduct("libsundials_cvode", :libsundials_cvode),
        LibraryProduct("libsundials_cvodes", :libsundials_cvodes),
        LibraryProduct("libsundials_ida", :libsundials_ida),
        LibraryProduct("libsundials_idas", :libsundials_idas),
        LibraryProduct("libsundials_kinsol", :libsundials_kinsol),
        LibraryProduct("libsundials_nvecmanyvector", :libsundials_nvecmanyvector),
        LibraryProduct("libsundials_nvecserial", :libsundials_nvecserial),
        LibraryProduct("libsundials_sunlinsolband", :libsundials_sunlinsolband),
        LibraryProduct("libsundials_sunlinsoldense", :libsundials_sunlinsoldense),
        LibraryProduct("libsundials_sunlinsolklu", :libsundials_sunlinsolklu),
        LibraryProduct("libsundials_sunlinsollapackband", :libsundials_sunlinsollapackband),
        LibraryProduct("libsundials_sunlinsollapackdense", :libsundials_sunlinsollapackdense),
        LibraryProduct("libsundials_sunlinsolpcg", :libsundials_sunlinsolpcg),
        LibraryProduct("libsundials_sunlinsolspbcgs", :libsundials_sunlinsolspbcgs),
        LibraryProduct("libsundials_sunlinsolspfgmr", :libsundials_sunlinsolspfgmr),
        LibraryProduct("libsundials_sunlinsolspgmr", :libsundials_sunlinsolspgmr),
        LibraryProduct("libsundials_sunlinsolsptfqmr", :libsundials_sunlinsolsptfqmr),
        LibraryProduct("libsundials_sunmatrixband", :libsundials_sunmatrixband),
        LibraryProduct("libsundials_sunmatrixdense", :libsundials_sunmatrixdense),
        LibraryProduct("libsundials_sunmatrixsparse", :libsundials_sunmatrixsparse),
        LibraryProduct("libsundials_sunnonlinsolauto", :libsundials_sunnonlinsolauto),
        LibraryProduct("libsundials_sunnonlinsolfixedpoint", :libsundials_sunnonlinsolfixedpoint),
        LibraryProduct("libsundials_sunnonlinsolnewton", :libsundials_sunnonlinsolnewton),
        LibraryProduct("libsundials_core", :libsundials_core),
    ]

    return products
end

# common install component of the script across both CPU and GPU builds
const install_script = raw"""
apk del cmake

cd $WORKSPACE/srcdir/sundials*
if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/Sundials_findklu_suffixes.patch
    LBT=blastrampoline-5
else
    LBT=blastrampoline
fi
mkdir build && cd build

# SUNDIALS passes its 64-bit `sunindextype` to LAPACK, so call LBT's ILP64 interface. Julia's
# OpenBLAS is LP64 on 32-bit platforms, which keep the unsuffixed names.
if [[ ${nbits} == 64 ]]; then
    for f in dgbtrf dgbtrs dgetrf dgetrs dgeev; do
        LAPACK_DEFINES+=" -D${f}_=${f}_64_"
    done
fi

CMAKE_FLAGS=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}"
    -DCMAKE_C_FLAGS="${LAPACK_DEFINES}"
    -DSUNDIALS_ENABLE_C_EXAMPLES=OFF
    -DSUNDIALS_ENABLE_KLU=ON
    -DKLU_INCLUDE_DIR="${includedir}/suitesparse"
    -DKLU_LIBRARY_DIR="${libdir}"
    -DSUNDIALS_ENABLE_KLU_CHECKS=OFF
    -DSUNDIALS_ENABLE_LAPACK=ON
    -DSUNDIALS_ENABLE_LAPACK_CHECKS=OFF
    -DSUNDIALS_LAPACK_CASE=lower
    -DSUNDIALS_LAPACK_UNDERSCORES=one
    -DBLAS_LIBRARIES="${libdir}/lib${LBT}.${dlext}"
    -DLAPACK_LIBRARIES="${libdir}/lib${LBT}.${dlext}"
)
"""
