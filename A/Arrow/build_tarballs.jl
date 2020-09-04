# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Arrow"
version = v"1.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/apache/arrow.git", "fcd44e4d5e9aea8b540d28e5fb6fc2427d804073")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd arrow/cpp/
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DARROW_COMPUTE=ON \
-DARROW_CSV=ON \
-DARROW_DATASET=ON \
-DARROW_JEMALLOC=OFF \
-DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
 Linux(:i686, libc=:glibc)
 Linux(:x86_64, libc=:glibc)
 #Linux(:aarch64, libc=:glibc)
 #Linux(:armv7l, libc=:glibc, call_abi=:eabihf)
 Linux(:powerpc64le, libc=:glibc)
 Linux(:i686, libc=:musl)
 Linux(:x86_64, libc=:musl)
 #Linux(:aarch64, libc=:musl)
 #Linux(:armv7l, libc=:musl, call_abi=:eabihf)
 MacOS(:x86_64)
 FreeBSD(:x86_64)
 #Windows(:i686)
 #Windows(:x86_64)
]

platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libarrow", :libarrow)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"4.8.5")
