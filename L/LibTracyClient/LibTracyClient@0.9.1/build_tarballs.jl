# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibTracyClient"
version = v"0.9.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wolfpld/tracy.git",
              "897aec5b062664d2485f4f9a213715d2e527e0ca"), # v0.9.1
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tracy*/
if [[ "${target}" != *-mingw* ]]; then
    echo "target_compile_definitions(TracyClient PUBLIC __STDC_FORMAT_MACROS)" >> CMakeLists.txt
else
    echo "target_compile_definitions(TracyClient PUBLIC WINVER=0x0602 _WIN32_WINNT=0x0602)" >> CMakeLists.txt
fi
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libTracyClient-freebsd-elfw.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libTracyClient-plot-config.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libTracyClient-no-sampling.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libTracyClient-rr-nopl-seq.patch
cmake -B static -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DTRACY_FIBERS=ON -DTRACY_ONLY_LOCALHOST=ON -DTRACY_NO_CODE_TRANSFER=ON -DTRACY_NO_FRAME_IMAGE=ON -DTRACY_NO_CRASH_HANDLER=ON -DTRACY_ON_DEMAND=ON -DTRACY_NO_SAMPLING=ON -DTRACY_TIMER_FALLBACK=ON .
cd static
make -j${nproc}
make install
cd ..
cmake -B shared -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DTRACY_FIBERS=ON -DTRACY_ONLY_LOCALHOST=ON -DTRACY_NO_CODE_TRANSFER=ON -DTRACY_NO_FRAME_IMAGE=ON -DTRACY_NO_CRASH_HANDLER=ON -DTRACY_ON_DEMAND=ON -DTRACY_NO_SAMPLING=ON -DTRACY_TIMER_FALLBACK=ON .
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")
