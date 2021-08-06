# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "msquic"
version = v"1.5.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/msquic.git",
              "a2c19d3ac386b8bb923e14d2607d42bffcfca0c7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/msquic
git submodule update --init --recursive
mkdir build && cd build
export CFLAGS="-Dstatic_assert=_Static_assert"
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(Sys.islinux, supported_platforms())

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="lttng_ust_jll", uuid="a2826780-45ff-53db-9dda-fd961bc58de1")),
    Dependency(PackageSpec(name="lttng_tools_jll", uuid="37591b3e-a3c2-50e0-b676-8bc36018f336")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
