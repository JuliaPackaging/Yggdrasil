# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "open62541"
version = v"1.3.7"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/open62541/open62541.git",
              "b8ac9e77f703e6ba5c012b886a8821037503daa6"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/open62541/
atomic_patch -p1 ../patches/0001-fix-core-Explicit-cast-to-avoid-compiler-warning-420.patch
atomic_patch -p1 ../patches/0002-refactor-pubsub-Fix-check-macros-and-slightly-clean-.patch
mkdir build && cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DUA_MULTITHREADING=100 \
    -DUA_ENABLE_SUBSCRIPTIONS=ON \
    -DUA_ENABLE_METHODCALLS=ON \
    -DUA_ENABLE_PARSING=ON \
    -DUA_ENABLE_NODEMANAGEMENT=ON \
    -DUA_ENABLE_AMALGAMATION=ON \
    -DUA_ENABLE_IMMUTABLE_NODES=ON \
    -DBUILD_SHARED_LIBS=ON \
    ..
make -j${nproc}
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libopen62541", :libopen62541)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
