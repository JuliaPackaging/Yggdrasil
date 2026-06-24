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
# For apple, fix the dylib ID
if [[ "${target}" == *-apple-* ]]; then
    install_name_tool -id "@rpath/libcadical.dylib" build/libcadical.so
fi
install -D -m755 build/libcadical.so "${prefix}/lib/libcadical.${dlext}"
install -D -m644 src/cadical.hpp "${prefix}/include/cadical.hpp"
install -D -m644 src/ccadical.h "${prefix}/include/ccadical.h"

# Build CaDiBack
cd ${WORKSPACE}/srcdir/cadiback
CXX=c++ ./configure
make -j${nproc}
# For apple, fix the dylib ID and the libcadical dependency
if [[ "${target}" == *-apple-* ]]; then
    install_name_tool -id "@rpath/libcadiback.dylib" libcadiback.so
    install_name_tool -change libcadical.so "@rpath/libcadical.dylib" libcadiback.so
fi
install -D -m755 libcadiback.so "${prefix}/lib/libcadiback.${dlext}"
install -D -m644 include/cadiback.h "${prefix}/include/cadiback.h"

# Build BreakID
cd ${WORKSPACE}/srcdir/breakid
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/breakid-cstdint.patch
mkdir build && cd build
cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSTATICCOMPILE=OFF \
    -DCMAKE_SKIP_INSTALL_RPATH=ON \
    -DENABLE_TESTING=OFF \
    -S ..
cmake --build . --config Release --parallel ${nproc}
cmake --install .

# Build CryptoMiniSat
cd ${WORKSPACE}/srcdir/cryptominisat
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cryptominisat-disable-fpu-check.patch
mkdir build && cd build
cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSTATICCOMPILE=OFF \
    -DCMAKE_SKIP_INSTALL_RPATH=ON \
    -DENABLE_TESTING=OFF \
    -DIPASIR=ON \
    -S ..
cmake --build . --config Release --parallel ${nproc}
cmake --install .

# Build SBVA
cd ${WORKSPACE}/srcdir/SBVA
if [[ "${target}" == *-linux-musl* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/sbva-musl-feenableexcept.patch
fi
mkdir build && cd build
ln -s ../scripts/*.sh .
cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSTATICCOMPILE=OFF \
    -DCMAKE_SKIP_INSTALL_RPATH=ON \
    -DENABLE_TESTING=OFF \
    -S ..
cmake --build . --config Release --parallel ${nproc}
cmake --install .

# Build Arjun
cd ${WORKSPACE}/srcdir/arjun
if [[ "${target}" == *-linux-musl* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/arjun-musl-feenableexcept.patch
fi
mkdir build && cd build
cmake \
    -DCMAKE_CXX_FLAGS="-I${prefix}/include" \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSTATICCOMPILE=OFF \
    -DCMAKE_SKIP_INSTALL_RPATH=ON \
    -DENABLE_TESTING=OFF \
    -S ..
cmake --build . --config Release --parallel ${nproc}
cmake --install .

# Build ApproxMC
cd ${WORKSPACE}/srcdir/approxmc
if [[ "${target}" == *-linux-musl* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/approxmc-musl-feenableexcept.patch
fi
mkdir build && cd build
cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSTATICCOMPILE=OFF \
    -DCMAKE_SKIP_INSTALL_RPATH=ON \
    -DENABLE_TESTING=OFF \
    -S ..
cmake --build . --config Release --parallel ${nproc}
cmake --install .

# Build Ganak
cd ${WORKSPACE}/srcdir/ganak
if [[ "${target}" == *-linux-musl* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/ganak-musl-feenableexcept.patch
fi
mkdir build && cd build
cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSTATICCOMPILE=OFF \
    -DCMAKE_SKIP_INSTALL_RPATH=ON \
    -DENABLE_TESTING=OFF \
    -S ..
cmake --build . --config Release --parallel ${nproc}
cmake --install .
# remove redundant files in lib/cmake/ganak
rm -f ${prefix}/lib/cmake/ganak/libganak.* ${prefix}/lib/cmake/ganak/*.hpp

install_license ${WORKSPACE}/srcdir/ganak/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(!Sys.iswindows, supported_platforms())
platforms = filter(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)  # excluded by mlpack_jll
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
    Dependency("FLINT_jll"; compat="~301.300.101"),
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
