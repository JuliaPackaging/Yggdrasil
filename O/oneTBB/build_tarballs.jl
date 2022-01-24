# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneTBB"
version = v"2021.5.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/oneapi-src/oneTBB/archive/refs/tags/v2021.5.0.tar.gz", "e5b57537c741400cf6134b428fc1689a649d7d38d9bb9c1b6d64f092ea28178a"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/oneTBB*

# We can't do Link-Time-Optimization with Clang, disable it.
atomic_patch -p1 ../patches/clang-no-lto.patch

if [[ ${target} == *-linux-musl* ]]; then
    # Adapt patch from https://github.com/oneapi-src/oneTBB/pull/203
    atomic_patch -p1 ../patches/musl.patch

elif [[ ${target} == *-mingw* ]]; then
    #derived from https://github.com/oneapi-src/oneTBB/commit/ce476173772f289c66ba98089618c1ff767ecea4, can hopefully be removed next release
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/lowercase-windows-include.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/NOMINMAX-defines.patch
    # `CreateSemaphoreEx` requires at least Windows Vista/Server 2008:
    # https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createsemaphoreexa
    export CXXFLAGS="-D_WIN32_WINNT=0x0600"
fi

mkdir build && cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DTBB_TEST=OFF \
    -DTBB_EXAMPLES=OFF \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# Disable platforms unlikely to work
filter!(p -> arch(p) ∉ ("armv6l", "armv7l"), platforms)

#i686 mingw fails with errors about _control87
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libtbbmalloc", :libtbbmalloc),
    LibraryProduct("libtbbmalloc_proxy", :libtbbmalloc_proxy),
    LibraryProduct(["libtbb", "libtbb12"], :libtbb),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
