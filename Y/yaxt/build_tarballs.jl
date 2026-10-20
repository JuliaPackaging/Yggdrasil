# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

# yaxt: Yet Another eXchange Tool (DKRZ), the MPI data exchange library used by YAC.
name = "yaxt"
version = v"0.12.1"

sources = [
    ArchiveSource("https://gitlab.dkrz.de/api/v4/projects/923/packages/generic/yaxt/$(version)/yaxt-$(version).tar.xz",
                  "115d550ba4ca87e31079de088ea5c7aba8bc509367ba707e2f5a42cdb3fd9723"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/yaxt-*

case ${bb_full_target} in
    *mpiabi*)        MPI_C_LIB="-lmpi_abi";;
    # MPICH on macOS keeps some global objects (e.g. MPI_UNWEIGHTED) in libpmpi
    *apple*mpich*)   MPI_C_LIB="-lmpi -lpmpi";;
    *)               MPI_C_LIB="-lmpi";;
esac

# Only the C library (libyaxt_c) is built: YAC and Julia only need the C API,
# and a Fortran build would require an `mpi.mod` matching each gfortran version.
# Configure detects cross-compilation (--build != --host) and then skips the
# MPI defect checks that would need to launch MPI programs.
# yaxt's bundled libtool patches use the bash-only `builtin` keyword, but
# /bin/sh in the build environment is busybox ash: force bash for libtool.
export CONFIG_SHELL=/bin/bash
# yaxt's configure interprets BUILD_CC/BUILD_CFLAGS/... as overrides for the
# compiler used to build the library itself, while BinaryBuilder sets them to
# the host (build machine) toolchain: unset them.
unset BUILD_CC BUILD_CXX BUILD_FC BUILD_CFLAGS BUILD_FCFLAGS BUILD_LDFLAGS BUILD_LIBS
# When target == build machine (x86_64-linux-musl) configure would not be in
# cross-compilation mode and would insist on a working MPI launcher to run its
# MPI defect checks: spell the build triplet differently to force cross mode.
BUILD_TRIPLET=${MACHTYPE}
if [[ "${target}" == "${MACHTYPE}" ]]; then
    BUILD_TRIPLET=$(echo ${MACHTYPE} | sed 's/-linux-/-pc-linux-/')
fi
${CONFIG_SHELL} ./configure \
    --prefix=${prefix} \
    --build=${BUILD_TRIPLET} \
    --host=${target} \
    --enable-shared \
    --disable-static \
    --with-pic \
    --without-example-programs \
    --without-perf-programs \
    --with-on-demand-check-programs \
    FC=no \
    CPPFLAGS="-I${includedir}" \
    LDFLAGS="-L${libdir}" \
    MPI_C_INCLUDE="-I${includedir}" \
    MPI_C_LIB="-L${libdir} ${MPI_C_LIB}" \
    SHELL=${CONFIG_SHELL}

make -j${nproc}
make install

install_license LICENSE
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = supported_platforms()
# yaxt requires a POSIX environment; Windows (MicrosoftMPI) is not supported upstream.
filter!(!Sys.iswindows, platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# yaxt uses MPI handles and constants (MPI_INT, MPI_KEYVAL_INVALID,
# MPI_COMBINER_*, MPI_COMM_WORLD, ...) in static initializers and `case` labels.
# With MPItrampoline these are not compile-time constants, so yaxt does not
# build against it without extensive patching.
filter!(p -> p["mpi"] != "mpitrampoline", platforms)

products = [
    LibraryProduct("libyaxt_c", :libyaxt_c),
]

dependencies = Dependency[]
append!(dependencies, platform_dependencies)

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.10", preferred_gcc_version=v"8")
