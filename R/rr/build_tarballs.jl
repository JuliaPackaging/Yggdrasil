# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "rr"
version = v"5.3.0"

# Collection of sources required to build rr
sources = [
    "https://github.com/mozilla/rr/archive/$(version).tar.gz" =>
    "440e90a68557a8111f483fc40ab5ed65d21d6b11426b3245e4221b930a86ca69"
]

# Bash recipe for building across all platforms
script = raw"""
pip3 install pexpect

cd $WORKSPACE/srcdir/rr-*/
mkdir obj && cd obj
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -Ddisable32bit=ON -DBUILD_TESTS=OFF -DWILL_RUN_TESTS=OFF ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# rr only supports Linux
# platforms = supported_platforms(exclude=(p)->typeof(p) !== Linux)
platforms = [Linux(:x86_64, libc=:musl)]

# The products that we will ensure are always built
products = [
    ExecutableProduct("rr", :rr)
]

# Dependencies that must be installed before this package can be built
# This is really a build dependency
dependencies = [
    "capnproto_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
              preferred_gcc_version=v"6")
