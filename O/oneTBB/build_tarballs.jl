# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneTBB"
version = v"2021.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/oneapi-src/oneTBB.git",
              "2dba2072869a189b9fdab3ffa431d3ea49059a19"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/oneTBB/

# Apply Musl patch from
# https://git.alpinelinux.org/aports/tree/community/libtbb/musl.patch
atomic_patch -p1 ../patches/musl.patch

mkdir build && cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libtbbmalloc", :libtbbmalloc),
    LibraryProduct("libtbbmalloc_proxy", :libtbbmalloc_proxy),
    LibraryProduct("libtbb", :libtbb),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
