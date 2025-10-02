using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "MPICH_MPIABI"
version_str = "4.3.1"
version = VersionNumber(version_str)

sources = [
    # MPICH source
    ArchiveSource("https://www.mpich.org/static/downloads/$(version)/mpich-$(version).tar.gz",
                  "acc11cb2bdc69678dc8bba747c24a28233c58596f81f03785bf2b7bb7a0ef7dc"),
    # The official MPI ABI C bindings.
    # There are no released versions. We choose a recent commit.
    # This corresponds to the MPI standard 5.0, MPI ABI 1.0.
    GitSource("https://github.com/mpi-forum/mpi-abi-stubs", "e4583674e6898da1fac6953da71bb1a205d74b37"),
    DirectorySource("bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/mpich*

# MPICH does not include `<pthread_np.h>` on FreeBSD: <https://github.com/pmodels/mpich/issues/6821>.
# (The MPICH developers say that this is a bug in MPICH and that
# `<pthread_np.h>` should not actually be used on FreeBSD.)
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/pthread_np.patch

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
    --enable-fast=ndebug,O3
    --enable-static=no
    --enable-mpi-abi
    --host=${target}
    --prefix=${prefix}
    --with-device=ch3
    --with-hwloc=${prefix}
)

./configure "${configure_flags[@]}"

# Build the library
make -j${nproc}

# Install the library
make install

# We don't want or need the non-ABI MPI include files, libraries, or binaries
ls -l ${includedir}
rm ${includedir}/mpi_abi.h
rm ${includedir}/mpi_proto.h
rm ${includedir}/mpi.h
rm ${includedir}/mpio.h
rm ${includedir}/mpiof.h

ls -l ${libdir}
rm ${libdir}/libmpi.*
rm ${libdir}/libmpich.*
rm ${libdir}/libmpichcxx.*
rm ${libdir}/libmpl.*
rm ${libdir}/libopa.*
rm -f ${libdir}/libpmpi.*
rm ${libdir}/pkgconfig/mpich.pc

ls -l ${bindir}
rm ${bindir}/mpic++

# Fix symlinks
rm ${bindir}/mpicc_abi
rm ${bindir}/mpicxx_abi
mv ${bindir}/mpicc ${bindir}/mpicc_abi
mv ${bindir}/mpicxx ${bindir}/mpicxx_abi

# Install license
install_license COPYRIGHT



cd ${WORKSPACE}/srcdir/mpi-abi-stubs

# Install the official header file
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
for p in platforms
    p["mpi"] = "MPIABI"
end

products = [
    # MPICH
    LibraryProduct("libmpi_abi", :libmpi),
    ExecutableProduct("mpiexec", :mpiexec),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("Hwloc_jll"; compat="2.12.2"),
    RuntimeDependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267");
                      compat="0.1", top_level=true),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, clang_use_lld=false, julia_compat="1.6")
