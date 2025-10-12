using BinaryBuilder
using BinaryBuilderBase
using Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

const version = v"7.5.0"

# Collection of sources required to build Sundials
function get_sources()
    return [
        GitSource("https://github.com/LLNL/sundials.git", "c8dabcea90ca8bf195474da120e4f3dd39aa711f"),
        DirectorySource("./bundled"),
    ]
end

# supported platforms for system
function get_platforms()
    platforms = expand_gfortran_versions(supported_platforms())
    filter!(p -> !(arch(p) == "powerpc64le" && libgfortran_version(p) < v"5"), platforms)

    return platforms
end

function get_dependencies()
    dependencies = [
        HostBuildDependency("CMake_jll"),
        Dependency("CompilerSupportLibraries_jll"),
        Dependency("OpenBLAS32_jll"),
        Dependency("SuiteSparse32_jll"),
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
        LibraryProduct("libsundials_sunnonlinsolfixedpoint", :libsundials_sunnonlinsolfixedpoint),
        LibraryProduct("libsundials_sunnonlinsolnewton", :libsundials_sunnonlinsolnewton),
        LibraryProduct("libsundials_core", :libsundials_core),
    ]

    return products
end

# common install component of the script across both CPU and GPU builds
const install_script = raw"""
apk del cmake

cd $WORKSPACE/srcdir/sundials*/cmake/tpl
if [[ "${target}" == *-mingw* ]]; then
    # Work around https://github.com/LLNL/sundials/issues/29
    # When looking for KLU libraries, CMake searches only for import libraries,
    # this patch ensures we look also for shared libraries.
    atomic_patch -p3 $WORKSPACE/srcdir/patches/Sundials_findklu_suffixes.patch
fi

# Build
cd $WORKSPACE/srcdir/sundials*
mkdir build && cd build

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" -DEXAMPLES_ENABLE_C=OFF -DENABLE_KLU=ON -DKLU_INCLUDE_DIR="${includedir}/suitesparse" -DKLU_LIBRARY_DIR="${libdir}" -DKLU_WORKS=ON -DENABLE_LAPACK=ON -DLAPACK_WORKS=ON -DBLA_VENDOR="OpenBLAS")
"""
