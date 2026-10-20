# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibTracyClient"
version = v"0.13.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wolfpld/tracy.git",
              "6cd7751479d4efd5c35f39e856891570a89dd060"), # v0.13.1 plus necessary patches
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tracy*/

# Common CMake flags
CMAKE_FLAGS=(
    -DCMAKE_INSTALL_PREFIX=$prefix
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DTRACY_FIBERS=ON
    -DTRACY_ONLY_LOCALHOST=ON
    -DTRACY_NO_CODE_TRANSFER=ON
    -DTRACY_NO_FRAME_IMAGE=ON
    -DTRACY_NO_CRASH_HANDLER=ON
    -DTRACY_ON_DEMAND=ON
    -DTRACY_NO_SAMPLING=ON
    -DTRACY_TIMER_FALLBACK=ON
    -DTRACY_PATCHABLE_NOPSLEDS=ON
)

if [[ "${target}" != *-mingw* ]]; then
    # Non-Windows: add __STDC_FORMAT_MACROS for PRIu64 etc.
    echo "target_compile_definitions(TracyClient PUBLIC __STDC_FORMAT_MACROS)" >> CMakeLists.txt
else
    # Windows/MinGW: Apply ETW compatibility patches for missing Windows 10+ SDK definitions
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libTracyClient-mingw-etw-compat.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libTracyClient-mingw-vsync-32bit.patch
fi

# FreeBSD ElfW compatibility
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libTracyClient-freebsd-elfw.patch

# Build static library
cmake -B static "${CMAKE_FLAGS[@]}" -DBUILD_SHARED_LIBS=OFF .
cd static
make -j${nproc}
make install
cd ..

# Build shared library
cmake -B shared "${CMAKE_FLAGS[@]}" -DBUILD_SHARED_LIBS=ON .
cd shared
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libTracyClient", :libTracyClient),
    FileProduct(["lib/libTracyClient.a", "lib/libTracyClient.lib"], :libTracyClient_static)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well
# Tracy v0.13+ requires C++20 with <latch> support, which needs GCC 11+
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"11")
