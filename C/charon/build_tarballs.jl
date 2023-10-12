# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "charon"
version = v"2.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.sandia.gov/app/uploads/sites/106/2022/06/charon-distrib-v2_2.tar.gz", "2743f39fb14166091f1e38581f9d85379a7db178b4b2d4ce5c8411fdec727073"),
    GitSource("https://github.com/TriBITSPub/TriBITS.git", "8c1874ca69280c9c9e8346fc96b2f068971e54d4"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/charon-all-changes.patch.patch
cd tcad-charon
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/charon-kokkos-compat.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/charon-no-rhytmos.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/panzerinclude.patch
mv src src2
sed -i 's/src/src2/g' PackagesList.cmake
# TODO: This should probably be fixed in Trilinos
sed -i 's|local/||g' /workspace/destdir/lib/external_packages/DLlib/DLlibConfig.cmake
install_license LICENSE/Charon_LICENSE
cd ..
rm /usr/bin/cmake
mkdir tcad-charon-build
cd tcad-charon-build/
export TRIBITS_BASE_DIR=${WORKSPACE}/srcdir/TriBITS
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ${WORKSPACE}/srcdir/tcad-charon -Dtcad-charon_ENABLE_Charon:BOOL=ON -DTPL_ENABLE_MPI=ON -Dtcad-charon_ENABLE_EXPLICIT_INSTANTIATION:BOOL=ON -DCharon_ENABLE_EXPLICIT_INSTANTIATION:BOOL=ON -Dtcad-charon_EXTRA_LINK_FLAGS="-lmpi"
make -j20 install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# Filter libgfortran3 - the corresponding GCC is too old to compiler some of
# the newer C++ constructs.
filter!(platforms) do p
    !(p["libgfortran_version"] in ("3.0.0", "4.0.0"))
end

# MPI Handling
augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Trilinos_jll", uuid="b6fd3212-6f87-5999-b9ea-021e9cd21b17"), compat="14.4.0"),
    Dependency("boost_jll"),
    HostBuildDependency(PackageSpec(name="CMake_jll"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10",
    preferred_gcc_version=v"9")
