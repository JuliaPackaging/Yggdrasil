# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "MAGEMin"
version = v"1.5.6"

MPItrampoline_compat_version="5.2.1"  

# Collection of sources required to complete build
sources = [GitSource("https://github.com/ComputationalThermodynamics/MAGEMin", 
                    "41b7861a26efda070ea1b7b453781d100f34e5f6")                 ]

# Bash recipe for building across all platforms
script = raw"""
cd MAGEMin*

if [[ "${target}" == *-mingw* ]]; then
    MPI_LIBS="-lmsmpi"
elif grep -q MPICH_NAME $prefix/include/mpi.h; then
    MPI_LIBS="-lmpi"
elif grep -q MPItrampoline $prefix/include/mpi.h; then
    MPI_LIBS="-lmpitrampoline"
elif grep -q OMPI_MAJOR_VERSION $prefix/include/mpi.h; then
    MPI_LIBS="-lmpi"
fi

CCFLAGS="-O3 -g -fPIC -std=c99"

if [[ "${target}" == *-apple* ]]; then 
    # Use Accelerate for Lapack dependencies
    LIBS="-L${libdir} -lm -framework Accelerate -lnlopt ${MPI_LIBS}"
    INC="-I${includedir}"
else
    LIBS="-L${libdir} -lm -lopenblas -lnlopt ${MPI_LIBS}"
    INC="-I${includedir}"
fi

# Compile library:
make -j${nproc} CC="${CC}" CCFLAGS="${CCFLAGS}" LIBS="${LIBS}" INC="${INC}" lib

# Compile binary
make -j${nproc} EXE_NAME="MAGEMin${exeext}" CC="${CC}" CCFLAGS="${CCFLAGS}" LIBS="${LIBS}" INC="${INC}" all

install -Dvm 755 libMAGEMin.dylib "${libdir}/libMAGEMin.${dlext}"
install -Dvm 755 MAGEMin${exeext} "${bindir}/MAGEMin${exeext}"

# store files
install -vm 644 src/*.h "${includedir}"

install_license LICENSE
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->Sys.isfreebsd(p) && arch(p) == "aarch64")
platforms = expand_gfortran_versions(platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.3.1", OpenMPI_compat="4.1.6, 5")

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)

# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libMAGEMin", :libMAGEMin)
    ExecutableProduct("MAGEMin", :MAGEMin)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="NLopt_jll", uuid="079eb43e-fd8e-5478-9966-2cf3e3edb778"))
    Dependency("OpenBLAS32_jll"; platforms=filter(!Sys.isapple, platforms))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"6")
