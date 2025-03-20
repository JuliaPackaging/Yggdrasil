# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "quickfix"
version = v"1.16.0"

# Collection of sources required to build CMake
sources = [
    GitSource("https://github.com/quickfix/quickfix.git", "92c85ca63fc260d16e24e0ece419ecdec9ffe868"),
    DirectorySource("./bundled")
]

# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

#filter julia versions to include only Julia >= 1.8 for LTS
julia_versions = filter(v-> v >= v"1.8", julia_versions)

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/quickfix

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

mkdir build && cd build

cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DHAVE_SSL=ON \
    -DHAVE_GETTIMEOFDAY=ON \
    -DCMAKE_CXX_FLAGS="-D__STDC_FORMAT_MACROS" \
    ..

make -j 4 install

install_license ${WORKSPACE}/srcdir/quickfix/LICENSE
"""

# Build for all supported platforms.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libquickfix", :libquickfix),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.8", preferred_gcc_version=v"7")
