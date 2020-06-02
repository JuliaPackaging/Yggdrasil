# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libint"
version = v"2.7.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/evaleev/libint/releases/download/v2.7.0-beta.5/libint-2.7.0-beta.5.tgz", "38c630d9b4433340079ebc7a93f05d7a285833883327bfc35dd208249e06f05f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libint-2.7.0-beta.5/
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DLIBINT2_BUILD_SHARED_AND_STATIC_LIBS=ON ..
cmake --build . --target install -- -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("liblibint2", :Libint2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Eigen_jll"
    "boost_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
