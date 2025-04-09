# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "PTSCOTCH"
version = v"7.0.6"
scotch_jll_version = v"7.0.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.inria.fr/scotch/scotch", "e231061e53f3ad63d6cce19d983be2c6c4301749"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/scotch*
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/scotch.patch"

mkdir -p src/dummysizes/build-host
cd src/dummysizes/build-host
cp ${WORKSPACE}/srcdir/patches/CMakeLists-dummysizes.txt ../CMakeLists.txt

CC=${CC_BUILD} cmake .. \
    -DBUILD_PTSCOTCH=ON \
    -DSCOTCH_VERSION=7 \
    -DSCOTCH_RELEASE=0 \
    -DSCOTCH_PATCHLEVEL=6 \
    -DCMAKE_BUILD_TYPE=Release

# make -j${nproc}
make

cd ${WORKSPACE}/srcdir/scotch*
mkdir build
cd build

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

CFLAGS=$FLAGS cmake .. \
    -DMPI_RUN_RESULT_C_libver_mpi_normal=1 \
    -DMPI_RUN_RESULT_C_libver_mpi_normal__TRYRUN_OUTPUT="" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DINTSIZE="32" \
    -DTHREADS=ON \
    -DMPI_THREAD_MULTIPLE=ON \
    -DBUILD_PTSCOTCH=ON \
    -DBUILD_LIBESMUMPS=ON \
    -DBUILD_LIBSCOTCHMETIS=ON \
    -DBUILD_DUMMYSIZES=OFF \
    -DINSTALL_METIS_HEADERS=OFF \
    -DENABLE_TESTS=OFF \
    -DLIBSCOTCHERR=scotcherr \
    -DLIBPTSCOTCHERR=ptscotcherr

# make -j${nproc}
make
make install

install_license ../LICENSE_en.txt
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# platforms = supported_platforms(; exclude=Sys.iswindows)
platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.2.1")

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

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
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0"); compat="1.0.8"),
    Dependency(PackageSpec(name="XZ_jll", uuid="ffd25f8a-64ca-5728-b0f7-c24cf3aae800")),
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9"), compat="=$(scotch_jll_version)"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"9.1.0",
               preferred_llvm_version=v"13.0.1")
