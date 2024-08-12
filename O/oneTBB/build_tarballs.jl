# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneTBB"
version = v"2021.12.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/oneapi-src/oneTBB.git",
              "9afd759b72c0c233cd5ea3c3c06b0894c9da9c54"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/oneTBB*

if [[ ${target} == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/mingw.patch"

    # `CreateSemaphoreEx` requires at least Windows Vista/Server 2008:
    # https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createsemaphoreexa
    export CXXFLAGS="-D_WIN32_WINNT=0x0600"
fi

if [[ ${target} == i686-linux-musl* ]]; then
    # Disable strong stack protection. Our musl version doesn't
    # provide the symbol `__stack_chk_fail_local` in the way GCC expects.
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/i686-musl.patch"
fi

cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DTBB_STRICT=OFF \
    -DTBB_TEST=OFF \
    -DTBB_EXAMPLES=OFF
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = expand_cxxstring_abis(supported_platforms())

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
