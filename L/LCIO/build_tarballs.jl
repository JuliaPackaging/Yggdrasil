# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LCIO"
version = v"02.13.01"

# Collection of sources required to build LCIO
sources = [
    "https://github.com/iLCSoft/LCIO/archive/v02-13-01.tar.gz" =>
    "aa572e2ba38c0cadd6a92fa933c3ed97e21d016c7982578d3f293901169f4ec0",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/LCIO-*/
mkdir build && cd build

cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64),
]
expand_cxxstring_abis(platforms)
# The products that we will ensure are always built
products = [
    LibraryProduct("liblcio", :liblcio),
    LibraryProduct("libsio", :libsio)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Zlib_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
