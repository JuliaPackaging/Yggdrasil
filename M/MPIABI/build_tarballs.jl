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
# [mpif](https://github.com/eschnett/mpif) or
# [vapaa](https://github.com/jeffhammond/vapaa), to provide Fortran
# bindings on top of this MPIABI.

sources = [
    # The official MPI ABI C bindings.
    # There are no released versions. We choose a recent commit.
    # This corresponds to the MPI standard 5.0, MPI ABI 1.0.
    GitSource("https://github.com/mpi-forum/mpi-abi-stubs", "e4583674e6898da1fac6953da71bb1a205d74b37"),

    # MPICH source, implementing the C bindings
    # ArchiveSource("https://www.mpich.org/static/downloads/$(version_str)/mpich-$(version_str).tar.gz",
    #               "acc11cb2bdc69678dc8bba747c24a28233c58596f81f03785bf2b7bb7a0ef7dc"),
    # ArchiveSource("https://www.mpich.org/static/downloads/$(version_str)/mpich-$(version_str).tar.gz",
    #               "2d738c70b0e45b787d5931b6ddfd0189e586773188e93c7fd1d934a99a9cc55d"),
    # This is the main branch as of 2025-10-05. This will likely turn into MPICH 5.0.
    GitSource("https://github.com/pmodels/mpich.git", "f47908fa4a74bf4ac29997202fb2967c8c59b0c9"),

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

git submodule update --init

./autogen.sh

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
configure_flags=(
    --build=${MACHTYPE}
    --disable-dependency-tracking
    --disable-doc
    --disable-fortran
    --enable-cxx=no
    --enable-fast=O3,ndebug,alwaysinline
    --enable-static=no
    --enable-mpi-abi
    --host=${target}
    --prefix=${prefix}/mpich
    --with-device=ch3
    --with-hwloc=${prefix}
)

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

# Build the library
make -j${nproc}

# Install the library into a tempoary directory ${prefix}/mpich.
# We are going to pick-and-choose only those installed files that we actually want.
make install

# Install the shared libraries
mv ${prefix}/mpich/lib/libmpi_abi.* ${libdir}

# Install almost all binaries (why not?)
mv ${prefix}/mpich/bin/* ${bindir}
rm ${bindir}/mpichversion       # needs libmpi.so
rm ${bindir}/mpivars            # needs libmpi.so

# Switch compiler wrappers to using the MPI ABI, and correct the install directory
rm ${bindir}/mpicc_abi
rm ${bindir}/mpicxx_abi
sed -i -e 's/mpi_abi=no/mpi_abi=yes/' ${bindir}/mpicc
sed -i -e 's/mpi_abi=no/mpi_abi=yes/' ${bindir}/mpicxx
sed -i -e "s+${prefix}/mpich+${prefix}+" ${bindir}/mpicc
sed -i -e "s+${prefix}/mpich+${prefix}+" ${bindir}/mpicxx

# Remove the temporary full install
rm -rf ${prefix}/mpich

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
    LibraryProduct("libmpi_abi", :libmpi; dont_dlopen=true),
    ExecutableProduct("mpiexec", :mpiexec),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("Hwloc_jll"; compat="2.12.2"),
    RuntimeDependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267");
                      compat="0.1", top_level=true),
]

# Build the tarballs.
# We need GCC 5 for C99
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"5")
