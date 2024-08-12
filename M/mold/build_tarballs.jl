# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mold"
version = v"1.11.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/rui314/mold.git",
              "cca255e6be069cdbc135c83fd16036d86b98b85e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mold/
mkdir build && cd build
if [[ "${target}" == i686-linux-gnu ]]; then
    # We need to link to librt for `clock_gettime` symbol
    export LDFLAGS=-lrt
fi
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(filter!(Sys.islinux, supported_platforms()))


# The products that we will ensure are always built
products = [
    ExecutableProduct("mold", :mold)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.8")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10")
