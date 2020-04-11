# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "rr"
version = v"5.3.1"

# Collection of sources required to build rr
sources = [
    GitSource("https://github.com/mozilla/rr.git",
              "c979313cf04ce78b09e5517b22f95ac068bb7c2d")
]

# Bash recipe for building across all platforms
script = raw"""
pip3 install pexpect

cd $WORKSPACE/srcdir/rr/

mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -Ddisable32bit=ON -DBUILD_TESTS=OFF -DWILL_RUN_TESTS=OFF ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# rr only supports Linux
platforms = [
    Linux(:x86_64, libc=:glibc),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("rr", :rr),
]

# Dependencies that must be installed before this package can be built
# This is really a build dependency
dependencies = [
    Dependency("capnproto_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"5") 
