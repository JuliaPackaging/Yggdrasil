# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libdatachannel"
version = v"0.20.2"
# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/paullouisageneau/libdatachannel.git", "9cbe6a2a1f21cde901bca9571581a96c6cda03cf")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libdatachannel
git submodule update --init --recursive --depth 1
cmake -B build -DUSE_GNUTLS=0 -DUSE_NICE=0 -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libdatachannel", :libdatachannel)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"13.2.0")
