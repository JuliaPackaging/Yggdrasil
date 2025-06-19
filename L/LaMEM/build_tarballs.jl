# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "LaMEM"
version = v"2.2.0"

PETSc_COMPAT_VERSION = "~3.22.0"    
MPItrampoline_compat_version=" 5.5.0"
MicrosoftMPI_compat_version="~10.1.4" 
MPICH_compat_version="~4.2.3"    
OpenMPI_compat_version="~5.0.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/UniMainzGeo/LaMEM", 
    "0f6a5a82f32a3db59871d6e254ae570a3100edad")
]

# Bash recipe for building across all platforms
script = raw"""

# When MPItrampoline is built, it remembers the compilers that were used to build it, and it then puts 
# these paths into the mpicc scripts. this doesn't work in BinaryBuilder, so you need to manually override this by 
# specifying MPITRAMPOLINE_CC etc. (From Erik Schnetter)
# These options were also used when building PETSc_jll, which is a key dependency of LaMEM.
export MPITRAMPOLINE_CC=${CC}
export MPITRAMPOLINE_CXX=${CXX}
export MPITRAMPOLINE_FC=${FC}

# Create required directories
mkdir $WORKSPACE/srcdir/LaMEM/bin
mkdir $WORKSPACE/srcdir/LaMEM/bin/opt
mkdir $WORKSPACE/srcdir/LaMEM/dep
mkdir $WORKSPACE/srcdir/LaMEM/dep/opt
mkdir $WORKSPACE/srcdir/LaMEM/lib
mkdir $WORKSPACE/srcdir/LaMEM/lib/opt

cd $WORKSPACE/srcdir/LaMEM/src
export PETSC_OPT=${libdir}/petsc/double_real_Int32/
make mode=opt clean_all 
make mode=opt all -j${nproc}
#make mode=opt all

# compile dynamic library
make mode=opt dylib -j${nproc}
#make mode=opt dylib

cd $WORKSPACE/srcdir/LaMEM/bin/opt

# On some windows versions it automatically puts the .exe extension; on others not. 
if [[ -f LaMEM ]]
then
    mv LaMEM LaMEM${exeext}
fi

cp LaMEM${exeext} $WORKSPACE/srcdir/LaMEM/
cd $WORKSPACE/srcdir/LaMEM

# Install binaries
install -Dvm 755 LaMEM* "${bindir}/LaMEM${exeext}"
install -vm 644 src/*.h "${includedir}"
install -Dvm 755 lib/opt/LaMEMLib.dylib "${libdir}/LaMEMLib.${dlext}"

# Install license
install_license LICENSE
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms(exclude=[Platform("i686", "windows"),
                                                                  Platform("i686","linux"; libc="musl"),
                                                                  Platform("i686","linux"; libc="gnu"),
                                                                  Platform("x86_64","freebsd"),
                                                                  Platform("armv6l","linux"; libc="musl"),
                                                                  Platform("armv7l","linux"; libc="musl"),
                                                                  Platform("armv7l","linux"; libc="gnu"),
                                                                  Platform("aarch64","linux"; libc="musl")]))

platforms, platform_dependencies = MPI.augment_platforms(platforms; 
                                        MPItrampoline_compat = MPItrampoline_compat_version,
                                        MPICH_compat         = MPICH_compat_version,
                                        MicrosoftMPI_compat  = MicrosoftMPI_compat_version,
                                        OpenMPI_compat       = OpenMPI_compat_version)

# mpitrampoline and libgfortran 3 don't seem to work
platforms = filter(p -> !(libgfortran_version(p) == v"3" && p.tags["mpi"]=="mpitrampoline"), platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv7l" && libc(p) == "glibc"), platforms)
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "x86_64" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "i686"), platforms)

# MPItrampoline does not seem to work with PETSc 3.22.0
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# powerpc64le only with libgfortran 5 or higher (as openblas is not defined for other cases)
platforms = filter(p -> !(p["arch"] == "powerpc64le" && (libgfortran_version(p) == v"3" || libgfortran_version(p) == v"4")), platforms)

# riscv64 is not supported
platforms = filter(p -> !(p["arch"] == "riscv64"), platforms)
platforms = filter(p -> !(p["arch"] == "aarch64" && libgfortran_version(p) == v"3" && os(p)=="linux"), platforms)
platforms = filter(p -> !(p["arch"] == "aarch64" && os(p)=="freebsd"), platforms)
platforms = filter(p -> !(p["arch"] == "aarch64" && os(p)=="linux" && libgfortran_version(p) != v"5" ), platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("LaMEM", :LaMEM)
    LibraryProduct("LaMEMLib", :LaMEMLib)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("PETSc_jll"; compat=PETSc_COMPAT_VERSION),
    Dependency("CompilerSupportLibraries_jll")
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"9")
               
