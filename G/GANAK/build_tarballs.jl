# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GANAK"
version = v"2.5.2"

# Collection of sources required to complete build
sources = [
  # exact commits used for Ganak 2.5.2 release (https://github.com/meelgroup/ganak/releases/tag/release%2F2.5.2)
  GitSource("https://github.com/meelgroup/ganak.git", "7ab65562ea23243163dea4b3a016c3c14ca29e52"),
  GitSource("https://github.com/meelgroup/arjun.git", "58ec9aff687c9adcd6a26f158a947c07794e43f6"),
  GitSource("https://github.com/meelgroup/SBVA.git", "0faa08cf3cc26ed855831c9dc16a3489c9ae010f"),
  GitSource("https://github.com/msoos/cryptominisat.git", "0f7487ebf5afa1ae3f7be279ba3709906a1c861d"),
  GitSource("https://github.com/meelgroup/approxmc.git", "56042dc9002dee312bb4be283d2bdf8bc2a67827"),
  GitSource("https://github.com/meelgroup/cadiback.git", "a35c4b98b6237b16ca0fd08dded8f8f51ff998a8"),
  GitSource("https://github.com/meelgroup/cadical.git", "81de5d2b5c68727b4d183ec5ceb56561f1b3b6e1"),
  # BreakID's commit hash is not mentioned in the Ganak release notes. Using the newest commit from the time of the Ganak 2.5.2 release.
  GitSource("https://github.com/meelgroup/breakid.git", "dee9744b7041cec373aa0489128b06a40fce43a1"),
  DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
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
install -D -m644 include/cadiback.h "${prefix}/include/cadiback.h"
cd ..

# Build BreakID
cd ${WORKSPACE}/srcdir/breakid
mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_TESTING=OFF \
    -DSTATICCOMPILE=OFF \
    ..
cmake --build . --config Release --parallel ${nproc}
cmake --install .
cd ../..

# Build CryptoMiniSat
cd $WORKSPACE/srcdir/cryptominisat
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

# Build SBVA
cd ${WORKSPACE}/srcdir/SBVA
mkdir build && cd build
ln -s ../scripts/*.sh .
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_TESTING=OFF \
    -DSTATICCOMPILE=OFF \
    ..
cmake --build . --config Release --parallel ${nproc}
cmake --install .
cd ../..

# Build Arjun
cd ${WORKSPACE}/srcdir/arjun
mkdir build && cd build
cmake \
    -DCMAKE_CXX_FLAGS="-I${prefix}/include" \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSTATICCOMPILE=OFF \
    -DENABLE_TESTING=OFF \
    -S ..
cmake --build . --config Release --parallel ${nproc}
cmake --install .
cd ../..

# Build ApproxMC
cd ${WORKSPACE}/srcdir/approxmc
mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSTATICCOMPILE=OFF \
    -DENABLE_TESTING=OFF \
    -S ..
cmake --build . --config Release --parallel ${nproc}
cmake --install .
cd ../..

# Build Ganak
cd ${WORKSPACE}/srcdir/ganak
mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSTATICCOMPILE=OFF \
    -DENABLE_TESTING=OFF \
    -S ..
cmake --build . --config Release --parallel ${nproc}
cmake --install .

install_license ${WORKSPACE}/srcdir/ganak/LICENSE.txt
"""

platforms = filter(p->(Sys.islinux(p) || Sys.isapple(p)), supported_platforms())
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("ganak", :ganak),
    LibraryProduct("libganak", :libganak),
]

# Dependencies that must be installed before this package can be built
dependencies = [
  Dependency("GMP_jll"; compat="6.2.1"),
  Dependency("MPFR_jll"),
  Dependency("FLINT_jll"),
  Dependency("Zlib_jll"),
  Dependency("cereal_jll"),
  Dependency("armadillo_jll"),
  Dependency("ensmallen_jll"),
  Dependency("mlpack_jll"),
]

# gcc version 11 is needed for `using enum ...;`
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
  julia_compat="1.6",
  preferred_gcc_version=v"11")
