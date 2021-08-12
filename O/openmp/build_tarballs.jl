# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LLVMOpenMP"
version = v"12.0.0"

sources = [
    ArchiveSource(
        "https://github.com/llvm/llvm-project/releases/download/llvmorg-$version/openmp-$version.src.tar.xz",
        "eb1b7022a247332114985ed155a8fb632c28ce7c35a476e2c0caf865150f167d"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openmp-*/

if [[ "${target}" == *-freebsd* ]]; then
    CMAKE_SHARED_LINKER_FLAGS="-Wl,--version-script=$(pwd)/runtime/src/exports_so.txt"
fi
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_SHARED_LINKER_FLAGS="${CMAKE_SHARED_LINKER_FLAGS}" \
    -DLIBOMP_INSTALL_ALIASES=OFF \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# disable for mingw for now, blocking on uasm
platforms = expand_cxxstring_abis(supported_platforms(exclude=Sys.iswindows))

# The products that we will ensure are always built
products = [
    LibraryProduct("libomp", :libomp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
