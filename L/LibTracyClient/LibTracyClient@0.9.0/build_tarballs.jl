# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibTracyClient"
version = v"0.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/wolfpld/tracy/archive/refs/tags/v0.9.tar.gz",
                  "93a91544e3d88f3bc4c405bad3dbc916ba951cdaadd5fcec1139af6fa56e6bfc"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tracy-0.9/
if [[ "${target}" != *-mingw* ]]; then
    echo "target_compile_definitions(TracyClient PUBLIC __STDC_FORMAT_MACROS)" >> CMakeLists.txt
else
    echo "target_compile_definitions(TracyClient PUBLIC WINVER=0x0602 _WIN32_WINNT=0x0602)" >> CMakeLists.txt
fi
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libTracyClient-freebsd-elfw.patch
cmake -B static -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DTRACY_FIBERS=ON .
cd static
make
make install
cd ..
cmake -B shared -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DTRACY_FIBERS=ON .
cd shared
make
make install
cd ..
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
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
