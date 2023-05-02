using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SCALAPACK32"
version = v"2.2.2"
scalapack_version = v"2.2.0"

sources = [
  GitSource("https://github.com/Reference-ScaLAPACK/scalapack", "0128dc24c6d018b61ceaac080640014e1d5ec344"),
  DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/scalapack
cp ${WORKSPACE}/srcdir/patches/SLmake.inc SLmake.inc
make lib

if grep -q MSMPI "${prefix}/include/mpi.h"; then
    gfortran -shared $(flagon -Wl,--whole-archive) libscalapack32.a $(flagon -Wl,--no-whole-archive) -lopenblas -L$libdir -lmsmpi -o ${libdir}/libscalapack32.${dlext}
elif grep -q MPICH "${prefix}/include/mpi.h"; then
    gfortran -shared $(flagon -Wl,--whole-archive) libscalapack32.a $(flagon -Wl,--no-whole-archive) -lopenblas -L$libdir -lmpifort -lmpi -o ${libdir}/libscalapack32.${dlext}
elif grep -q MPItrampoline "${prefix}/include/mpi.h"; then
    gfortran -shared $(flagon -Wl,--whole-archive) libscalapack32.a $(flagon -Wl,--no-whole-archive) -lopenblas -L$libdir -lmpitrampoline -o ${libdir}/libscalapack32.${dlext}
elif grep -q OMPI_MAJOR_VERSION $prefix/include/mpi.h; then
    gfortran -shared $(flagon -Wl,--whole-archive) libscalapack32.a $(flagon -Wl,--no-whole-archive) -lopenblas -L$libdir -lmpi_usempif08 -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi -o ${libdir}/libscalapack32.${dlext}
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
