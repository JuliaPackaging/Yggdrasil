# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LLVMLibUnwind"
version = v"11.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/libunwind-11.0.0.src.tar.xz", "8455011c33b14abfe57b2fd9803fb610316b16d4c9818bec552287e2ba68922f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libunwind-11.0.0.src

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=$prefix)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DLIBUNWIND_INCLUDE_DOCS=OFF)
CMAKE_FLAGS+=(-DLIBUNWIND_ENABLE_PEDANTIC=OFF)

# TODO: Work around to build on Windows 64-bit
if [[ ${target} == x86_64-w64-mingw32 ]]; then
    CMAKE_FLAGS+=(-DLIBUNWIND_ENABLE_THREADS=OFF)
fi

cmake ${CMAKE_FLAGS[@]}
make -j${nprocs}
make install

# Move over the DLL. TODO: There may be a CMAKE flag for this.
if [[ ${target} == *mingw32* ]]; then
    mkdir -p $prefix/bin
    mv -v lib/libunwind.dll $prefix/bin/
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# platforms = supported_platforms(;experimental=true)


# The products that we will ensure are always built
products = [
    LibraryProduct("libunwind", :libunwind)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6.1.0")
