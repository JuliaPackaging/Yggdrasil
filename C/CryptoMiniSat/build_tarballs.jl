# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "CryptoMiniSat"
version = v"6.0.0"
cryptominisat_version = v"5.13.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/meelgroup/cadical.git", "d3a78bc5ba014771e975d1ccf2a00e239048068d"),
    GitSource("https://github.com/meelgroup/cadiback.git", "09c1e99a2ff8f583d479639d879f3a815d0d8189"),
    GitSource("https://github.com/msoos/cryptominisat.git", "e60d03528e7bb2ad577f3ca5a8e6e478fe7407f1"),
    DirectorySource("./bundled"),
    # For C++20 support on macOS
    FileSource("https://github.com/alexey-lysiuk/macos-sdk/releases/download/13.3/MacOSX13.3.tar.xz",
               "71ae3a78ab1be6c45cf52ce44cb29a3cc27ed312c9f7884ee88e303a862a1404"),
]

# Bash recipe for building across all platforms
script = raw"""
# For C++20 support on macOS
if [[ "${target}" == *-apple-darwin* ]]; then
    rm -rf /opt/${target}/${target}/sys-root/System /opt/${target}/${target}/sys-root/usr/include/libxml2
    tar --extract --file=${WORKSPACE}/srcdir/MacOSX13.3.tar.xz --directory="/opt/${target}/${target}/sys-root/." --strip-components=1 MacOSX13.3.sdk/System MacOSX13.3.sdk/usr
    export MACOSX_DEPLOYMENT_TARGET=13.3
fi

# Build CaDiCaL
cd ${WORKSPACE}/srcdir/cadical
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cadical-cross-compile.patch
if [[ "${target}" == *-freebsd* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cadical-freebsd-headers.patch
fi
CXXFLAGS="-fPIC" ./configure --competition
make -j${nproc}
install -D -m755 build/libcadical.so "${prefix}/lib/libcadical.${dlext}"
install -D -m644 src/cadical.hpp "${prefix}/include/cadical.hpp"
install -D -m644 src/ccadical.h "${prefix}/include/ccadical.h"
cd ..

# Build CaDiBack
cd ${WORKSPACE}/srcdir/cadiback
# remove this patch when updating CaDiBack to a newer version that fixes this
if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cadiback-windows-link-order.patch
fi
CXX=c++ ./configure
make -j${nproc}
install -D -m755 libcadiback.so "${prefix}/lib/libcadiback.${dlext}"
install -D -m644 cadiback.h "${prefix}/include/cadiback.h"
cd ..

# Build CryptoMiniSat
cd $WORKSPACE/srcdir/cryptominisat
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cadiback-include.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cryptominisat-disable-fpu-check.patch
mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DENABLE_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DIPASIR=ON \
    -DSTATICCOMPILE=OFF \
    -S ..
cmake --build . --config Release --parallel ${nproc}
cmake --install .

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
    LibraryProduct(["libcryptominisat5", "libcryptominisat5win"], :libcryptominisat5),
    LibraryProduct("libipasircryptominisat5", :libipasircryptominisat5)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("Zlib_jll"),
]

platforms, platform_dependencies = MPI.augment_platforms(platforms)
# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
# gcc version 10 is needed for the ranges library
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"10")
