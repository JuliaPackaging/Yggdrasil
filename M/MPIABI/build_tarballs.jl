using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "MPIABI"
# We use semver for this package. Since this represents and ABI, and
# not a package, it doesn't make sense to follow e.g. MPI's or
# OpenMPI's released versions.
#
# We are currently at version 0.1 because some details of the ABI are still being hashed out, e.g. the library SOVERSION.
version = v"0.1.1"

# The MPI ABI does not provide Fortran bindings. Packages using this
# ABI should use a different package, e.g.
# [mpif](https://github.com/eschnett/mpif) or
# [vapaa](https://github.com/jeffhammond/vapaa), to provide Fortran
# bindings on top of this MPIABI.

sources = [
    # The official MPI ABI C bindings.
    # There are no released versions. We choose a recent commit.
    # This corresponds to the MPI standard 5.0, MPI ABI 1.0.
    GitSource("https://github.com/mpi-forum/mpi-abi-stubs", "a1183ce6e048341cc65414fd21d928b8cfc9709f"),

    # MPICH source, implementing the C bindings
    ArchiveSource("https://www.mpich.org/static/downloads/5.0.0b1/mpich-5.0.0b1.tar.gz",
                  "fb862b0c733c004477ba95ee879b90b17940726ed11a9427b68d90fb86888412"),

    # Patches
    DirectorySource("bundled"),
]

script = raw"""
################################################################################
# Build MPICH.
#
# MPICH is our default implementation.
# In the future we will introduce a mechanism to swap out MPICH for another MPI implementation.

cd ${WORKSPACE}/srcdir/mpich*

# MPICH does not include `<pthread_np.h>` on FreeBSD: <https://github.com/pmodels/mpich/issues/6821>.
# (The MPICH developers say that this is a bug in MPICH and that
# `<pthread_np.h>` should not actually be used on FreeBSD.)
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/pthread_np.patch

# See <https://github.com/pmodels/mpich/issues/7690> and <https://github.com/pmodels/mpich/issues/7691>
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mpich.patch

# - Do not install doc and man files which contain files which clashing names on
#   case-insensitive file systems:
#   * https://github.com/JuliaPackaging/Yggdrasil/pull/315
#   * https://github.com/JuliaPackaging/Yggdrasil/issues/6344
# - `--enable-fast=all,O3` leads to very long compile times for the
#   file `src/mpi/coll/mpir_coll.c`. It seems we need to avoid
#   `alwaysinline`.
# - We need to use `ch3` because `ch4` breaks on some systems, e.g. on
#   x86_64 macOS. See
#   <https://github.com/JuliaPackaging/Yggdrasil/pull/10249#discussion_r1975948816> for a brief
#   discussion.
# - We configure with Fortran although we do not provide any Fortran
#   bindings. This ensures that the C API still supports Fortran types.
configure_flags=(
    --build=${MACHTYPE}
    --disable-dependency-tracking
    --disable-doc
    --enable-fortran
    --enable-cxx=no
    --enable-fast=O3,ndebug,alwaysinline
    --enable-static=no
    --enable-mpi-abi
    --host=${target}
    --prefix=${prefix}
    --with-device=ch3
    --with-hwloc=${prefix}
)

# Define some obscure undocumented variables needed for cross compilation of
# the Fortran bindings.  See for example
# * https://stackoverflow.com/q/56759636/2442087
# * https://github.com/pmodels/mpich/blob/d10400d7a8238dc3c8464184238202ecacfb53c7/doc/installguide/cfile
export CROSS_F77_SIZEOF_INTEGER=4
export CROSS_F77_SIZEOF_REAL=4
export CROSS_F77_SIZEOF_DOUBLE_PRECISION=8
export CROSS_F77_SIZEOF_LOGICAL=4
export CROSS_F77_TRUE_VALUE=1
export CROSS_F77_FALSE_VALUE=0

if [[ ${nbits} == 32 ]]; then
    export CROSS_F90_ADDRESS_KIND=4
else
    export CROSS_F90_ADDRESS_KIND=8
fi
export CROSS_F90_OFFSET_KIND=8
export CROSS_F90_INTEGER_KIND=4
export CROSS_F90_INTEGER_MODEL=9
export CROSS_F90_REAL_MODEL=6,37
export CROSS_F90_DOUBLE_MODEL=15,307
export CROSS_F90_ALL_INTEGER_MODELS=2,1,4,2,9,4,18,8,
export CROSS_F90_INTEGER_MODEL_MAP={2,1,1},{4,2,2},{9,4,4},{18,8,8},

if [[ "${target}" == i686-linux-musl ]]; then
    # Our `i686-linux-musl` platform is a bit rotten: it can run C programs,
    # but not C++ or Fortran.  `configure` runs a C program to determine
    # whether it's cross-compiling or not, but when it comes to running
    # Fortran programs, it fails.  In addition, `configure` ignores the
    # above exported variables if it believes it's doing a native build.
    # Small hack: edit `configure` script to force `cross_compiling` to be
    # always "yes".
    sed -i 's/cross_compiling=no/cross_compiling=yes/g' configure
    configure_flags+=(ac_cv_sizeof_bool="1")
fi

if [[ "${target}" == aarch64-apple-* ]]; then
    configure_flags+=(
        FFLAGS=-fallow-argument-mismatch
        FCFLAGS=-fallow-argument-mismatch
    )
fi

if [[ ${target} != *x86_64* ]]; then
    # The configure test incorrectly enables AVX on arm64 architectures.
    # (There is still a run-time CPU check, so this option is fine in principle.)
    configure_flags+=(
        pac_cv_found_avx=no
        pac_cv_found_avx512f=no
    )
fi

# Use these options to enable accelerators:
# --with-cuda=
# --with-hip=
# --with-ze=

./configure "${configure_flags[@]}"

# Remove empty `-l` flags from libtool
# (Why are they there? They should not be.)
# Run the command several times to handle multiple (overlapping) occurrences.
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool

# Build and install the library
make -j${nproc}
make install

# Remove all that provide the MPICH ABI (instead of the MPI ABI)

ls -lR ${prefix}

rm ${bindir}/mpicc_abi
rm ${bindir}/mpichversion       # needs libmpi.so
rm ${bindir}/mpicxx_abi
rm ${bindir}/mpif77
rm ${bindir}/mpif90
rm ${bindir}/mpifort
rm ${bindir}/mpivars            # needs libmpi.so
# Switch compiler wrappers to using the MPI ABI, and correct the install directory
sed -i -e 's/mpi_abi=no/mpi_abi=yes/' ${bindir}/mpicc
sed -i -e 's/mpi_abi=no/mpi_abi=yes/' ${bindir}/mpicxx

rm ${includedir}/mpi.h
rm ${includedir}/mpi.mod
rm ${includedir}/mpi_abi.h
rm ${includedir}/mpi_base.mod
rm -f ${includedir}/mpi_c_interface.mod
rm -f ${includedir}/mpi_c_interface_cdesc.mod
rm -f ${includedir}/mpi_c_interface_glue.mod
rm -f ${includedir}/mpi_c_interface_nobuf.mod
rm -f ${includedir}/mpi_c_interface_types.mod
rm ${includedir}/mpi_constants.mod
rm -f ${includedir}/mpi_f08.mod
rm -f ${includedir}/mpi_f08_callbacks.mod
rm -f ${includedir}/mpi_f08_compile_constants.mod
rm -f ${includedir}/mpi_f08_link_constants.mod
rm -f ${includedir}/mpi_f08_types.mod
rm ${includedir}/mpi_proto.h
rm ${includedir}/mpi_sizeofs.mod
rm ${includedir}/mpif.h
rm ${includedir}/pmpi_base.mod
rm -f ${includedir}/pmpi_f08.mod

rm ${libdir}/libfmpich.*
rm ${libdir}/libmpi.*
rm ${libdir}/libmpich.*
rm ${libdir}/libmpichcxx.*
rm ${libdir}/libmpichf90.*
rm ${libdir}/libmpifort.*
rm ${libdir}/libmpl.*
rm ${libdir}/libopa.*
rm -f ${libdir}/libpmpi.*
rm ${libdir}/pkgconfig/mpich.pc

ls -lR ${prefix}

# Install license
install_license COPYRIGHT



################################################################################
# C bindings for MPI ABI

cd ${WORKSPACE}/srcdir/mpi-abi-stubs

# Add the C bindings for C/Fortran interoperability.
#
# MPI programs may expect it, but the MPI ABI standard intentionally excludes it.
# We choose to provide a Fortran ABI as well, and therefore we need to define it here.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fortran.patch

# Install the official MPI ABI header file
install -Dvm 644 mpi.h ${includedir}/mpi.h

# Install the license
install_license LICENSE
"""

# We are inlining `$(MPI.augment)` because we did not update Yggdrasil's `platforms/mpi.jl` yet
augment_platform_block = """
    using Base.BinaryPlatforms

    # Can't use Preferences since we might be running this very early with a non-existing Manifest
    MPIPreferences_UUID = Base.UUID("3da0fdf6-3ccc-4f1b-acd9-58baa6c99267")
    const preferences = Base.get_preferences(MPIPreferences_UUID)

    # Keep logic in sync with MPIPreferences.jl
    function augment_mpi!(platform)
        # Doesn't need to be `const` since we depend on MPIPreferences so we
        # invalidate the cache when it changes.
        # Note: MPIPreferences uses `Sys.iswindows()` without the `platform` argument.
        binary = get(preferences, "binary", Sys.iswindows(platform) ? "MicrosoftMPI_jll" : "MPICH_jll")

        abi = if binary == "system"
            let abi = get(preferences, "abi", nothing)
                if abi === nothing
                    error("MPIPreferences: Inconsistent state detected, binary set to system, but no ABI set.")
                else
                    abi
                end
            end
        elseif binary == "MPIABI_jll"
            "MPIABI"
        elseif binary == "MPICH_jll"
            "MPICH"
        elseif binary == "MPICH_CUDA_jll"
            "MPICH"
        elseif binary == "MPItrampoline_jll"
            "MPItrampoline"
        elseif binary == "MicrosoftMPI_jll"
            "MicrosoftMPI"
        elseif binary == "OpenMPI_jll"
            "OpenMPI"
        else
            error("Unknown binary: ", binary)
        end

        if !haskey(platform, "mpi")
            platform["mpi"] = abi
        end
        return platform
    end

    augment_platform!(platform::Platform) = augment_mpi!(platform)
    """

platforms = supported_platforms()

filter!(!Sys.iswindows, platforms)

# Add `mpi+mpiabi` platform tag
foreach(platforms) do p
    p["mpi"] = "MPIABI"
end

products = [
    LibraryProduct("libmpi_abi", :libmpi),
    ExecutableProduct("mpiexec", :mpiexec),
]

dependencies = [
    Dependency("Hwloc_jll"; compat="2.12.2"),
    RuntimeDependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267");
                      compat="0.1", top_level=true),
]

# Build the tarballs.
# We need GCC 5 for C99
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"5")
