# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "LaMEM"
version = v"3.1.0"

# PETSc_jll 3.25.4 uses MPI.augment_platforms' default compat bounds; LaMEM must resolve the
# same MPI per platform because petscsys.h errors out when mpi.h reports a different version.
PETSc_COMPAT_VERSION = "3.25.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/UniMainzGeo/LaMEM",
    "7e7a012ebbaacf85b5e0ecd963a2ddb83b5cbd1a"),  # v3.1.0
    DirectorySource("./bundled"),
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

cd $WORKSPACE/srcdir/LaMEM

atomic_patch -p1 $WORKSPACE/srcdir/patches/stdc-format-macros.patch

cd $WORKSPACE/srcdir/LaMEM/src

# LaMEM 3.0.0 added an explicit `-std=c++17` flag (vs the previous reliance on PETSc's
# `-std=gnu++17`), which switches MinGW onto strict ISO mode and hides M_PI (a GNU/POSIX
# extension to <math.h>/<cmath>) unless _USE_MATH_DEFINES is defined before the first
# include of <math.h>/<cmath>. src/Tensor.cpp and src/scaling.cpp use M_PI directly, so
# without this the Windows build fails with "M_PI was not declared in this scope".
# Setting CXXFLAGS doesn't reach the compile line (PETSc's conf/variables re-defines it),
# so patch the define directly into the two files that need it.
if [[ "${target}" == *mingw* ]]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/mingw-use-math-defines.patch
fi

export PETSC_OPT=${libdir}/petsc/double_real_Int32/

# LaMEM >= 3.1.0 picks its extra warning flags from the compiler name behind the MPI wrapper
# and errors out on anything but g++/clang++/icpx; name the family of our toolchain instead.
if [[ "${target}" == *-apple-* || "${target}" == *freebsd* ]]; then
    LAMEM_CXX_COMPILER=clang++
else
    LAMEM_CXX_COMPILER=g++
fi
MAKE_ARGS=(mode=opt CXX_COMPILER=${LAMEM_CXX_COMPILER})

# `uname -m` says ppc64le, which LaMEM's platform check does not recognise
if [[ "${target}" == powerpc64le-* ]]; then
    MAKE_ARGS+=(PLATFORM=powerpc64le)
fi

make "${MAKE_ARGS[@]}" clean_all
make "${MAKE_ARGS[@]}" all -j${nproc}

# compile dynamic library
make "${MAKE_ARGS[@]}" dylib -j${nproc}

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

# PETSc_jll has no 32-bit builds, so LaMEM cannot be built there either
filter!(p -> nbits(p) != 32, platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

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
    # PETSc_jll does not dlopen its per-configuration libraries, so LaMEMLib cannot be
    # loaded at init; consumers dlopen it after PETSc's double_real_Int32 variant.
    LibraryProduct("LaMEMLib", :LaMEMLib; dont_dlopen=true)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("PETSc_jll"; compat=PETSc_COMPAT_VERSION),
    Dependency("CompilerSupportLibraries_jll"),
    # PETSc's mpiabi build links libmpif (Fortran MPI bindings); the MPI augmentation
    # only provides MPIABI_jll (libmpi_abi), so add mpif_jll for mpiabi platforms to
    # satisfy LaMEM's dlopen audit. Mirrors PETSc_jll's own recipe.
    Dependency("mpif_jll"; compat="1.0.0", platforms=filter(p -> p["mpi"] == "mpiabi", platforms)),
    # On Windows, PETSc_jll 3.22.1 links libscalapack32 statically into LaMEM's executable,
    # so SCALAPACK32_jll must be present in the prefix or the link fails with
    # `ld: cannot find -lscalapack32`. (On Linux/macOS it's resolved via libpetsc itself.)
    Dependency("SCALAPACK32_jll"; compat="2.2.302", platforms=filter(p -> Sys.iswindows(p), platforms)),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.12", preferred_gcc_version = v"9")
               
