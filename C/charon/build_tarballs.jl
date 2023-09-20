# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

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
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
rm /usr/bin/cmake
mkdir tcad-charon-build
cd tcad-charon-build/
export TRIBITS_BASE_DIR=${WORKSPACE}/srcdir/TriBITS
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ${WORKSPACE}/srcdir/tcad-charon -Dtcad-charon_ENABLE_Charon:BOOL=ON -DTPL_ENABLE_SEACASNemspread=OFF -DTPL_ENABLE_SEACASNemslice=OFF -DTPL_ENABLE_SEACASExodiff=OFF -DTPL_ENABLE_SEACASEpu=OFF -DTPL_ENABLE_SEACAS=OFF
make -j20 install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Trilinos_jll", uuid="b6fd3212-6f87-5999-b9ea-021e9cd21b17"), compat="14.4.0")
    HostBuildDependency(PackageSpec(name="CMake_jll"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
