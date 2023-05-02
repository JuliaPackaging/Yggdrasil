using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SCALAPACK32"
version = v"2.2.2"
scalapack_version = v"2.2.1" # + some additional fixes

sources = [
  GitSource("https://github.com/Reference-ScaLAPACK/scalapack", "2072b8602f0a5a84d77a712121f7715c58a2e80d"),
  DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/scalapack
cp ${WORKSPACE}/srcdir/patches/SLmake.inc SLmake.inc
make -j${nproc} lib

if grep -q MSMPI "${prefix}/include/mpi.h"; then
    $CC -shared $(flagon -Wl,--whole-archive) libscalapack32.a $(flagon -Wl,--no-whole-archive) -lgfortran -lopenblas -L$libdir -lmsmpi -o ${libdir}/libscalapack32.${dlext}
elif grep -q MPICH "${prefix}/include/mpi.h"; then
    $CC -shared $(flagon -Wl,--whole-archive) libscalapack32.a $(flagon -Wl,--no-whole-archive) -lgfortran -lopenblas -L$libdir -lmpifort -lmpi -o ${libdir}/libscalapack32.${dlext}
elif grep -q MPItrampoline "${prefix}/include/mpi.h"; then
    $CC -shared $(flagon -Wl,--whole-archive) libscalapack32.a $(flagon -Wl,--no-whole-archive) -lgfortran -lopenblas -L$libdir -lmpitrampoline -o ${libdir}/libscalapack32.${dlext}
elif grep -q OMPI_MAJOR_VERSION $prefix/include/mpi.h; then
    $CC -shared $(flagon -Wl,--whole-archive) libscalapack32.a $(flagon -Wl,--no-whole-archive) -lgfortran -lopenblas -L$libdir -lmpi_usempif08 -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi -o ${libdir}/libscalapack32.${dlext}
fi
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = expand_gfortran_versions(supported_platforms())

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# Internal compiler error for v2.2.0 for:
# - aarch64-linux-musl-libgfortran4-mpi+mpich
# - aarch64-linux-musl-libgfortran4-mpi+openmpi
platforms = filter(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libc(p) == "musl" && libgfortran_version(p) == v"4" && p["mpi"] == "mpich"), platforms)
platforms = filter(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libc(p) == "musl" && libgfortran_version(p) == v"4" && p["mpi"] == "openmpi"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libscalapack32", :libscalapack32),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
]
append!(dependencies, platform_dependencies)

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6")
