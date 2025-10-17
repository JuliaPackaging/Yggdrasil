# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "CryptoMiniSat"
version = v"5.11.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/msoos/cryptominisat.git", "219a457501fd0796bd871bd6b3735b130598430c"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cryptominisat
atomic_patch -p1 ../Yalsatpatch.patch
atomic_patch -p1 ../Picosat.patch
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_PYTHON_INTERFACE=OFF \
    -DIPASIR=ON \
    -DNOM4RI=ON \
    -DBoost_USE_STATIC_LIBS=OFF \
    ..
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/cryptominisat/LICENSE.txt
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = Product[
    ExecutableProduct(["cryptominisat5", "cryptominisat5win"], :cryptominisat5),
    ExecutableProduct("cryptominisat5_simple", :cryptominisat5_simple),
    LibraryProduct(["libcryptominisat5", "libcryptominisat5win"], :libcryptominisat5),
    LibraryProduct("libipasircryptominisat5", :libipasircryptominisat5)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"; compat="=1.79.0"),
    Dependency("Zlib_jll"),
    Dependency("SQLite_jll"),
]

platforms, platform_dependencies = MPI.augment_platforms(platforms)
# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"8")
