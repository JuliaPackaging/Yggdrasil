# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LinearElasticity"
version = v"5.0"

# Collection of sources required to build MMG
sources = [
    GitSource("https://github.com/ISCDtoolbox/LinearElasticity.git",
              "58ace131fd1af9293ded9f84f2a6447147a8ecdc"), # master @ May 6, 2021
    GitSource("https://github.com/ISCDtoolbox/Commons.git",
              "57f0b0ed46d45a12fa60c42bce2c6fa73c84bc30"), # master @ Jul 23, 2021
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Commons
if [[ "${target}" == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Commons.mingw.patch"
elif [[ "${target}" == *freebsd* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Commons.freebsd.patch"
else
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Commons.patch"
fi
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON
make -j${nproc}
make install

cd ${WORKSPACE}/srcdir/LinearElasticity
if [[ "${target}" == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/LinearElasticity.mingw.patch"
else
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/LinearElasticity.patch"
fi
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_STANDARD_LIBRARIES="${LDFLAGS}" \
    -DBUILD_SHARED_LIBS=ON
make -j${nproc}
make install
install_license ../LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libCommons", :libCommons),
    LibraryProduct("libElas", :libElas),
    ExecutableProduct("elastic", :elastic)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
