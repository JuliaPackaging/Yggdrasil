# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "PTSCOTCH"
version = v"6.1.5"
scotch_jll_version = "6.1.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.inria.fr/scotch/scotch", "40b60f8965913178cd66e3572eb23efa6ce18ade"), # <-- v"6.1.3"
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scotch*
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/native_build.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Makefile.patch"
if [[ "${target}" == *apple* || "${target}" == *freebsd* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/OSX_FreeBSD.patch"
fi
if [[ "${target}" == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Windows.patch"
fi
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/mpi-constants.patch"
cd src
make ptscotch
make ptesmumps
cp ../lib/libpt* ${libdir}
cp ../include/p* ${includedir}
install_license ../LICENSE_en.txt
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.2.1")

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libptscotcherr", :libptscotcherr),
    LibraryProduct("libptscotcherrexit", :libptscotcherrexit),
    LibraryProduct("libptscotchparmetis", :libptscotchparmetis),
    LibraryProduct("libptscotch", :libptscotch, dont_dlopen=true),
    LibraryProduct("libptesmumps", :libptesmumps)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency("SCOTCH_jll"; compat=scotch_jll_version)
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"9.1.0")
