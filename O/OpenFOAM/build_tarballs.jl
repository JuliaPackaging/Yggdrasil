# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenFOAM"
version = v"8.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/OpenFOAM/OpenFOAM-8/archive/version-8.tar.gz",
                  "94ba11cbaaa12fbb5b356e01758df403ac8832d69da309a5d79f76f42eb008fc"),
    DirectorySource("./bundled"),
]

# In order to set up OpenFOAM, we need to know the version of some of the
# dependencies.
const SCOTCH_VERSION = "6.1.0"

# Bash recipe for building across all platforms
script = "SCOTCH_VERSION=$(SCOTCH_VERSION)\n" * raw"""
cd ${WORKSPACE}/srcdir/OpenFOAM*
atomic_patch -p1 ../patches/etc-bashrc.patch

# Set rpaths in all C/C++ compilers
LDFLAGS=""
for dir in "" "/dummy" "/openmpi-system"; do
    LDFLAGS="${LDFLAGS} -Wl,-rpath=\$\$ORIGIN${dir} -Wl,-rpath-link=${PWD}/platforms/linux64GccDPInt32Opt/lib${dir}"
done
sed -i "s?-m64?-m64 ${LDFLAGS}?g" wmake/rules/*/c*

# Set version of Scotch
echo "export SCOTCH_VERSION=${SCOTCH_VERSION}" > etc/config.sh/scotch
echo "export SCOTCH_ARCH_PATH=${prefix}"      >> etc/config.sh/scotch

# Set up to use our MPI (MPICH)
sed -i 's/WM_MPLIB=SYSTEMOPENMPI/WM_MPLIB=SYSTEMMPI/g' etc/bashrc
export MPI_ROOT="${prefix}"
export MPI_ARCH_FLAGS=""
export MPI_ARCH_INC="-I${includedir}"
export MPI_ARCH_LIBS="-L${libdir} -lmpi"

# HACK!  Explanation: sourcing `etc/bashrc` would result in (non-fatal) errors, that would
# spring our traps.  As a workaround, we run the rest of script in a subshell (sigh), allow
# failures in `source`, but exit if other commands fail.  We also don't mess up our system
# by sourcing the script.  Inspired by
# https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=openfoam&id=c8374a4890add0117e972629cf556c49b9a8ec36

bash -c "
  source etc/bashrc
  ./Allwmake -j${nproc} || exit 1"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;exclude=Sys.iswindows)

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("MPICH_jll"),
    Dependency("flex_jll"),
    Dependency("SCOTCH_jll"; compat=SCOTCH_VERSION),
    Dependency("PTSCOTCH_jll"),
    Dependency("METIS_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"5", julia_compat="1.6")
