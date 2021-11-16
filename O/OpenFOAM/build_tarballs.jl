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

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/OpenFOAM*
atomic_patch -p1 ../patches/etc-bashrc.patch
# Set rpaths in all C/C++ compilers
LDFLAGS=""
for dir in "" "/dummy" "/openmpi-system"; do
    LDFLAGS="${LDFLAGS} -Wl,-rpath=\$\$ORIGIN${dir} -Wl,-rpath-link=${PWD}/platforms/linux64GccDPInt32Opt/lib${dir}"
done
sed -i "s?-m64?-m64 ${LDFLAGS}?g" wmake/rules/*/c*
# Allow failures, sigh
source etc/bashrc || true
./Allwmake -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;exclude=Sys.iswindows)

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # TODO: Try to use MPICH_jll, like PTSCHOT_jll, otherwise we have a conflict
    # between the two dependencies.
    Dependency("OpenMPI_jll"),
    Dependency("flex_jll"),
    Dependency("SCOTCH_jll"),
    Dependency("PTSCOTCH_jll"),
    Dependency("METIS_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"5", julia_compat="1.6")
