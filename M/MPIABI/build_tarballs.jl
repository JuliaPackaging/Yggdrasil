using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "MPIABI"
# We use semver for this package. Since this represents and ABI, and
# not a package, it doesn't make sense to follow e.g. MPI's or
# OpenMPI's released versions.
version = v"1.0.0"

# The MPI ABI does not provide Fortran bindings. Packages using this
# ABI should use a different package, e.g.
# [mpif](https://github.com/eschnett/mpif), to provide Fortran
# bindings on top of this MPIABI.

sources = [
    # The official MPI ABI C bindings.
    # There are no released versions. We choose a recent commit.
    # This corresponds to the MPI standard 5.0, MPI ABI 1.0.
    GitSource("https://github.com/mpi-forum/mpi-abi-stubs", "e3a9e9b16f86099723d287b6ab477626ab4956b8"),

    # MPICH source, implementing the C bindings.
    #
    # We build from a commit on `main` rather than from the 5.0.1 release.
    # This avoids a few patches that we would otherwise have to apply.
    GitSource("https://github.com/pmodels/mpich", "ab53493dad85ffee0fc95812b250e1c8dacf7982"),

    # MPICH's submodules, at the commits that the MPICH commit above records.
    # The release tarball bundled these; a Git checkout does not, and the build
    # sandbox cannot run `git submodule update`, so they come as their own
    # sources. `modules/ucx` is deliberately absent: we never select the ucx
    # netmod, and it has a nested submodule of its own. See `--without-ucx`
    # below.
    GitSource("https://github.com/pmodels/hwloc", "42bebfa5e4b96c99c2482645c8eb86d4755ef23b";
              unpack_target="mpich-modules"),
    GitSource("https://github.com/pmodels/json-c", "79ad1c9b9fcc846e6bc31f47b801d11ba6d8613a";
              unpack_target="mpich-modules"),
    GitSource("https://github.com/pmodels/libfabric", "090c8f066d4a9e54f324a26fb019554512ddd8e0";
              unpack_target="mpich-modules"),
    GitSource("https://github.com/pmodels/mydef_boot", "ea2d6852486755eb12e255f760e2eb62f5446329";
              unpack_target="mpich-modules"),

    # Patches
    DirectorySource("bundled"),
]

script = raw"""
################################################################################
# Build MPICH.
#
# MPICH is our default implementation.

cd ${WORKSPACE}/srcdir/mpich

# Put MPICH's submodules in place. The checkout has them as empty gitlink
# directories; `autogen.sh` needs real source trees there.
mkdir -p modules
for module in ${WORKSPACE}/srcdir/mpich-modules/*; do
    rm -rf modules/$(basename ${module})
    mv ${module} modules/
done

# MPICH does not include `<pthread_np.h>` on FreeBSD: <https://github.com/pmodels/mpich/issues/6821>.
# (The MPICH developers say that this is a bug in MPICH and that
# `<pthread_np.h>` should not actually be used on FreeBSD.)
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/pthread_np.patch

# Add some Fortran-related C bindings that are not present in the MPI ABI
cp ${WORKSPACE}/srcdir/files/fortran_binding_abi.c src/binding/abi/fortran_binding_abi.c
perl -pi -e 's!src/binding/abi/c_binding_abi.c!src/binding/abi/c_binding_abi.c src/binding/abi/fortran_binding_abi.c!' src/binding/abi/Makefile.mk
# Fail loudly if upstream renamed the file we hooked into. Without this the
# bindings would silently be left out of the library, and the failure would only
# show up much later as undefined symbols when something links against it.
grep -q 'fortran_binding_abi\.c' src/binding/abi/Makefile.mk

# `--without-ucx`: `autogen.sh` insists on every submodule it might need being
# checked out, and we do not ship `modules/ucx` (see the sources above). The ucx
# netmod is never selected by the `--with-device` options below.
./autogen.sh --without-ucx

# - Do not install doc and man files which contain files which clashing names on
#   case-insensitive file systems:
#   * https://github.com/JuliaPackaging/Yggdrasil/pull/315
#   * https://github.com/JuliaPackaging/Yggdrasil/issues/6344
# - `--enable-fast=all,O3` leads to very long compile times for the
#   file `src/mpi/coll/mpir_coll.c`. It seems we need to avoid
#   `alwaysinline`.
# - We configure with Fortran although we do not provide any Fortran
#   bindings. This ensures that the C API still supports the Fortran types.
configure_flags=(
    --build=${MACHTYPE}
    --disable-dependency-tracking
    --disable-doc
    --enable-fortran
    --enable-cxx=no
    --enable-fast=O3,ndebug,alwaysinline
    --enable-shared=yes
    --enable-static=no
    --enable-mpi-abi
    --host=${target}
    --prefix=${prefix}
    --with-device=ch3
    --with-hwloc=${prefix}
)
if [[ "${target}" == *-apple-* ]]; then
    # Add options from MacPorts
    configure_flags+=(
        --enable-timer-type=mach_absolute_time
        --with-device=ch4:ofi:tcp
        --with-pm=hydra
    )
fi

# Define variables needed for cross compilation of the Fortran bindings.  See for example
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

# Stop here if libtool decided against shared libraries anyway, rather than
# building for many minutes and failing much later with a confusing error.
if ! grep -q '^build_libtool_libs=yes' libtool; then
    echo "error: configure did not enable shared libraries:" >&2
    grep '^build_libtool_libs=\|^can_build_shared=' libtool >&2
    exit 1
fi

# Remove empty `-l` flags from libtool
# (Why are they there? They should not be.)
# Run the command several times to handle multiple (overlapping) occurrences.
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool
sed -i 's/"-l /"/g;s/ -l / /g;s/-l"/"/g' libtool

# Build and install the library
make -j${nproc}
make install

# Switch compiler wrappers to using the MPI ABI, and correct the install directory
sed -i -e 's/mpi_abi=no/mpi_abi=yes/' ${bindir}/mpicc
sed -i -e 's/mpi_abi=no/mpi_abi=yes/' ${bindir}/mpicxx

# Expose the standard ABI only: remove everything that provides MPICH's own ABI
# (its `mpi.h`, its Fortran modules, its non-ABI libraries and wrappers). A
# consumer that still finds any of these can silently build against them instead
# of against the ABI.
#
# A pattern that matches nothing is a warning rather than an error: upstream
# renames files from time to time, and a stale entry should not break the build.
# Unmatched globs stay literal here, so the `-e` test below rejects them.

ls -lR ${prefix}

prune=(
    ${bindir}/mpicc_abi
    ${bindir}/mpichversion      # needs libmpi.so
    ${bindir}/mpicxx_abi
    ${bindir}/mpif77
    ${bindir}/mpif90
    ${bindir}/mpifort           # mpif installs its own `mpifort`
    ${bindir}/mpivars           # needs libmpi.so

    ${includedir}/mpi.h         # replaced by the official ABI header below
    ${includedir}/mpi.mod
    ${includedir}/mpi_abi.h
    ${includedir}/mpi_base.mod
    ${includedir}/mpi_c_interface.mod
    ${includedir}/mpi_c_interface_cdesc.mod
    ${includedir}/mpi_c_interface_glue.mod
    ${includedir}/mpi_c_interface_nobuf.mod
    ${includedir}/mpi_c_interface_types.mod
    ${includedir}/mpi_constants.mod
    ${includedir}/mpi_f08.mod
    ${includedir}/mpi_f08_callbacks.mod
    ${includedir}/mpi_f08_compile_constants.mod
    ${includedir}/mpi_f08_link_constants.mod
    ${includedir}/mpi_f08_types.mod
    ${includedir}/mpi_proto.h
    ${includedir}/mpi_sizeofs.mod
    ${includedir}/mpif.h
    ${includedir}/mpix.h
    ${includedir}/pmpi_base.mod
    ${includedir}/pmpi_f08.mod

    ${libdir}/libfmpich.*
    ${libdir}/libmpi.*          # the non-ABI library
    ${libdir}/libmpich.*
    ${libdir}/libmpichcxx.*
    ${libdir}/libmpichf90.*
    ${libdir}/libmpifort.*
    ${libdir}/libmpl.*
    ${libdir}/libopa.*
    ${libdir}/libpmpi.*
    ${libdir}/pkgconfig/mpich.pc
)
for path in "${prune[@]}"; do
    if [[ -e ${path} || -L ${path} ]]; then
        rm -rf "${path}"
    else
        echo "warning: ${path} does not exist; has MPICH's install layout changed?"
    fi
done

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
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mpi.h.patch

# Install the official MPI ABI header file
install -Dvm 644 mpi.h ${includedir}/mpi.h

# Install the license
install_license LICENSE
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
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
