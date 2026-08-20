# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "PTSCOTCH"
version = v"7.0.11"
scotch_jll_version = version

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.inria.fr/scotch/scotch", "626b88ce70edabb993bbee463f6c28ae2899af69"),
    # conda-forge patches for cross-building
    GitSource("https://github.com/conda-forge/scotch-feedstock", "73cc602e57759cd4a12823586aa46e29d7a7e6f7"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/scotch

# Apply conda-forge patches
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0001-put-metis-headers-in-include-scotch.patch
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0002-fix-ptesmumps.h.patch
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0003-win-fix-ssize_t.patch
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0004-win-fix-context.c.patch
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0005-use-external-dummysizes.patch
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0006-win-fix-graph-match-scan.patch
atomic_patch -p1 $WORKSPACE/srcdir/scotch-feedstock/recipe/0007-allow-overriding-pthread_mutex_t-size.patch

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mpi-constants.patch

################################################################################

# SCOTCH builds helper programs `dummysizes` and `ptdummysizes`, and runs them to
# extract sizes of datatypes. This does not work when cross-building.
# We build them ahead of time with the host compiler.

mkdir -p src/dummysizes/build-host
cd src/dummysizes
cp ${WORKSPACE}/srcdir/patches/CMakeLists-dummysizes.txt CMakeLists.txt

OPTIONS=(
    -DBUILD_PTSCOTCH=ON
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN}
    -DINTSIZE="32"
    -DSCOTCH_PATCHLEVEL=11
    -DSCOTCH_RELEASE=0
    -DSCOTCH_VERSION=7
    -DTHREADS=ON
)
cmake -B build-host ${OPTIONS[@]}
cmake --build build-host --parallel ${nproc}

################################################################################

# Now build PT-SCOTCH

cd ${WORKSPACE}/srcdir/scotch

FLAGS=""
if [[ "${target}" == *linux* ]]; then
    FLAGS="-lrt"
fi
if [[ "${target}" == *linux-musl* ]]; then
    FLAGS="-lrt -D_GNU_SOURCE"
fi
if [[ "${target}" == *freebsd* ]]; then
    FLAGS="-Dcpu_set_t=cpuset_t -D__BSD_VISIBLE"
fi

OPTIONS=(
    # SCOTCH forces `MPI_DETERMINE_LIBRARY_VERSION`, which `FindMPI` implements
    # with `try_run`. Pre-seed the results for every MPI language component,
    # otherwise CMake bails out when cross-compiling.
    -DMPI_RUN_RESULT_C_libver_mpi_normal=1
    -DMPI_RUN_RESULT_C_libver_mpi_normal__TRYRUN_OUTPUT=""
    # `FindMPI` picks whichever Fortran binding is the "highest" available, so
    # seed all three candidates
    -DMPI_RUN_RESULT_Fortran_libver_mpi_F08_MODULE=1
    -DMPI_RUN_RESULT_Fortran_libver_mpi_F08_MODULE__TRYRUN_OUTPUT=""
    -DMPI_RUN_RESULT_Fortran_libver_mpi_F90_MODULE=1
    -DMPI_RUN_RESULT_Fortran_libver_mpi_F90_MODULE__TRYRUN_OUTPUT=""
    -DMPI_RUN_RESULT_Fortran_libver_mpi_F77_HEADER=1
    -DMPI_RUN_RESULT_Fortran_libver_mpi_F77_HEADER__TRYRUN_OUTPUT=""
    -DBUILD_LIBESMUMPS=ON
    -DBUILD_LIBSCOTCHMETIS=ON
    -DBUILD_PTSCOTCH=ON
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_DUMMYSIZES=OFF
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=$prefix
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DENABLE_TESTS=OFF
    -DINSTALL_METIS_HEADERS=OFF
    -DINTSIZE="32"
    -DMPI_THREAD_MULTIPLE=ON
    -DTHREADS=ON
)

CFLAGS=$FLAGS cmake -B build ${OPTIONS[@]}
cmake --build build --parallel ${nproc}

# `libscotch` and friends come from `SCOTCH_jll`; only install the PT-SCOTCH part
cmake --install build --component libptscotch

install_license ${WORKSPACE}/srcdir/scotch/LICENSE_en.txt
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libptscotch", :libptscotch),
    LibraryProduct("libptesmumps", :libptesmumps),
    LibraryProduct("libptscotcherr", :libptscotcherr),
    LibraryProduct("libptscotcherrexit", :libptscotcherrexit),
    LibraryProduct("libptscotchparmetisv3", :libptscotchparmetisv3)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0"); compat="1.0.9"),
    Dependency(PackageSpec(name="XZ_jll", uuid="ffd25f8a-64ca-5728-b0f7-c24cf3aae800")),
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9"), compat="=$(scotch_jll_version)"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"9.1.0",
               preferred_llvm_version=v"13.0.1")
