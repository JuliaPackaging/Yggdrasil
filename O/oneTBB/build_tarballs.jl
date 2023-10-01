# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "oneTBB"
version = v"2021.9.0"

# Collection of sources required to build hwloc
sources = [
    GitSource("https://github.com/oneapi-src/oneTBB", "a00cc3b8b5fb4d8115e9de56bf713157073ed68c"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/oneTBB

rm -f /usr/share/cmake/Modules/Compiler/._*.cmake

if [[ ${target} == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/mingw.patch"

    # `CreateSemaphoreEx` requires at least Windows Vista/Server 2008:
    # https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createsemaphoreexa
    export CXXFLAGS="-D_WIN32_WINNT=0x0600"
fi

cmake -B build -S . \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DTBB_EXAMPLES=OFF \
    -DTBB_STRICT=OFF \
    -DTBB_TEST=OFF
cmake --build build --parallel ${nproc}
cmake --build build --parallel ${nproc} --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
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
