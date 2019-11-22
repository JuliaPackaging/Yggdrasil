# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libportaudio"
version = v"19.6.0"


# Collection of sources required to build libportaudio. Not all of these
# are used for all platforms.
sources = [
    "http://portaudio.com/archives/pa_stable_v190600_20161030.tgz" =>
        "f5a21d7dcd6ee84397446fa1fa1a0675bb2e8a4a6dceb4305a8404698d8d1513",

    "http://www.steinberg.net/sdk_downloads/ASIOSDK2.3.1.zip" =>
        "31074764475059448a9b7a56f103f4723ed60465e0e9d1a9446ca03dcf840f04"
        ]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# move the ASIO SDK to where CMake can find it
mv "asiosdk2.3.1 svnrev312937/ASIOSDK2.3.1" asiosdk2.3.1

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=ON \
    ../portaudio/
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc)
    Linux(:x86_64, libc=:glibc)
    Linux(:aarch64, libc=:glibc)
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf)
    Linux(:powerpc64le, libc=:glibc)
    MacOS(:x86_64)
    Windows(:i686)
    Windows(:x86_64)
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libportaudio", :libportaudio)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
