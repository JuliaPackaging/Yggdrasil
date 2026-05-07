# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "PaRSEC"
version = v"4.0.2411"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ICLDisco/parsec.git",
              "cdb2e7f5148b503e381eab110b77d9575540cbb9"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/parsec

# Make parsec-ptgpp import optional when cross-compiling (we only need libparsec).
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0002-fix-cmake-crosscompile-optional-ptgpp.patch

# Fix parsec_param_enable_mpi_overtake declared only under #if defined() but
# used in the #else branch too.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-fix-mpi-overtake-undeclared.patch

# Detect the MPI implementation to give cmake's FindMPI a reliable hint.
# cmake cannot run the mpicc wrapper during cross-compilation, so we pass
# the full library path directly. All supported MPI JLLs are MPI 3.0+.
MPI_LIBS="mpi"
if grep -q MPItrampoline ${includedir}/mpi.h 2>/dev/null; then
    MPI_LIBS="mpitrampoline"
elif grep -q "MPI_ABI_VERSION" ${includedir}/mpi.h 2>/dev/null && [[ -f ${libdir}/libmpi_abi.${dlext} ]]; then
    MPI_LIBS="mpi_abi"
elif [[ "${target}" == *-mingw* ]]; then
    MPI_LIBS="msmpi"
fi

MPI_LIB_FILE="${libdir}/lib${MPI_LIBS}.${dlext}"

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DPARSEC_DIST_WITH_MPI=ON \
    -DPARSEC_GPU_WITH_CUDA=OFF \
    -DPARSEC_GPU_WITH_HIP=OFF \
    -DPARSEC_GPU_WITH_LEVEL_ZERO=OFF \
    -DPARSEC_GPU_WITH_OPENCL=OFF \
    -DPARSEC_DEBUG=OFF \
    -DPARSEC_PROF_TRACE=OFF \
    -DPARSEC_PROF_PINS=OFF \
    -DBUILD_TOOLS=OFF \
    -DSUPPORT_FORTRAN=OFF \
    -DBUILD_TESTING=OFF \
    -DMPI_C_LIBRARIES="${MPI_LIB_FILE}" \
    -DMPI_CXX_LIBRARIES="${MPI_LIB_FILE}" \
    -DMPI_C_INCLUDE_PATH="${prefix}/include" \
    -DMPI_C_INCLUDE_DIRS="${prefix}/include" \
    -DMPI_CXX_INCLUDE_DIRS="${prefix}/include" \
    -DPARSEC_HAVE_MPI_20=TRUE \
    -DPARSEC_HAVE_MPI_30=TRUE \
    -DPARSEC_HAVE_MPI_OVERTAKE=TRUE \
    -DHWLOC_ROOT=${prefix}

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE.txt
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
# Windows is excluded: PaRSEC is primarily an HPC Linux/macOS framework and
# Windows MPI support is not well-tested upstream.
platforms = supported_platforms()
platforms = filter(p -> !Sys.iswindows(p), platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libparsec", :libparsec),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    RuntimeDependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267");
                      compat="0.1", top_level=true),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"9")
