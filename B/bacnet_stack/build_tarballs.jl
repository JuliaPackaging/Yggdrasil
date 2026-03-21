# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bacnet_stack"
version = v"1.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/bacnet-stack/bacnet-stack.git", "c111154993cce5dc0e3edd10c602bce51e2d2d61"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBACNET_STACK_BUILD_APPS=OFF \
    -DBACNET_BUILD_SERVER_MINI_APP=OFF \
    -DBACNET_BUILD_SERVER_BASIC_APP=OFF \
    -DBACNET_BUILD_PIFACE_APP=OFF \
    -DBACNET_BUILD_BACPOLL_APP=OFF \
    -DBACNET_BUILD_BACDISCOVER_APP=OFF \
    bacnet-stack
cmake -B build bacnet-stack
cmake --build build --parallel ${nproc}
cmake --install build
mkdir -p ${prefix}/share/licenses/bacnet_stack 
cp bacnet-stack/license/* ${prefix}/share/licenses/bacnet_stack
"""

# Currently linux, windows and apple are supported, but FreeBSD fails because it cannot find #include <dispatch/dispatch.h>
# According to ChatGPT, one would have to explicitely install the libdispatch port of Apple’s Grand Central Dispatch APIs.
# If you require FreeBSD support, maybe this is the way to go (add another build script for libdispatch and add it as a dependency?)
platforms = supported_platforms(; exclude=(p) -> Sys.isbsd(p))

# The products that we will ensure are always built
products = [
    LibraryProduct("libbacnet-stack", :libbacnet_stack)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"13.2.0")
