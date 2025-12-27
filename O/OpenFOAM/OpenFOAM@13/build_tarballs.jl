# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "OpenFOAM"
version = v"13.0.20250911"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/OpenFOAM/OpenFOAM-13.git",
              "cde978a97c939b1d5c8f2efce4e12f9b9ec460a9"),
#    DirectorySource("./bundled"),
]

# In order to set up OpenFOAM, we need to know the version of some of the
# dependencies.
const SCOTCH_VERSION = "6.1.0"
const SCOTCH_COMPAT_VERSION = "6.1.3"

# Bash recipe for building across all platforms
script = "SCOTCH_VERSION=$(SCOTCH_VERSION)\n" * raw"""
cd ${WORKSPACE}/srcdir/OpenFOAM*

#atomic_patch -p1 ../patches/etc-bashrc.patch
ln -sf /proc/self/fd /dev/fd

# Set rpath-link in all C/C++ compilers
LDFLAGS=""
for dir in "" "/dummy" "/mpi-system"; do
    LDFLAGS="${LDFLAGS} -Wl,-rpath-link=${PWD}/platforms/linux64GccDPInt32Opt/lib${dir}"
done
sed -i "s?-m64?-m64 ${LDFLAGS}?g" wmake/rules/*/c*

# Set version of Scotch
echo "export SCOTCH_VERSION=${SCOTCH_VERSION}" > etc/config.sh/scotch
echo "export SCOTCH_ARCH_PATH=${prefix}"      >> etc/config.sh/scotch

# Set up to use our MPI
sed -i 's/WM_MPLIB=SYSTEMOPENMPI/WM_MPLIB=SYSTEMMPI/g' etc/bashrc
export MPI_ROOT="${prefix}"
export MPI_ARCH_FLAGS=""
export MPI_ARCH_INC="-I${includedir}"
if grep -q MPICH_NAME $prefix/include/mpi.h; then
    export MPI_ARCH_LIBS="-L${libdir} -lmpi"
elif grep -q MPItrampoline $prefix/include/mpi.h; then
    export MPI_ARCH_LIBS="-L${libdir} -lmpitrampoline"
elif grep -q OMPI_MAJOR_VERSION $prefix/include/mpi.h; then
    export MPI_ARCH_LIBS="-L${libdir} -lmpi"
fi

# Set up the environment.  Note, this script may internally have some failing command, which
# would spring our traps, so we have to allow failures, sigh
source etc/bashrc || true

# Remove zoltan decomposition
export ZOLTAN_VERSION=zoltan-none
export ZOLTAN_TYPE=none

# Build!
./Allwmake -j${nproc}

# Highly advanced installation process (inspired by Debian:
# https://salsa.debian.org/science-team/openfoam/-/tree/master/debian)
mkdir -p ${libdir} ${bindir} ${prefix}/share/openfoam
cp platforms/linux64GccDPInt32Opt/lib/{,dummy/,mpi-system/}*.${dlext}* ${libdir}
cp platforms/linux64GccDPInt32Opt/bin/* ${bindir}
cp -r -L bin/* ${bindir}
cp -r etc/ ${prefix}/share/openfoam/
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
]
platforms = expand_cxxstring_abis(platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libOpenFOAM", :libOpenFOAM; dont_dlopen=true),
    ExecutableProduct("simpleFoam", :simpleFoam),
    FileProduct("share/openfoam/etc", :openfoam_etc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("flex_jll"),
    Dependency("SCOTCH_jll"; compat=SCOTCH_COMPAT_VERSION),
    Dependency("PTSCOTCH_jll"),
    Dependency("METIS_jll"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"9")
