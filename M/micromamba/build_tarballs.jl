# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "micromamba"
version = v"1.2.0"
build = "1"

# Collection of sources required to build micromamba
# These are actually just the conda packages for each platform
sources = [
    FileSource("https://conda.anaconda.org/conda-forge/linux-64/micromamba-$version-$build.tar.bz2",
        "7845801006ca30e36a79dc428c28e625c37ace7178c6285f0cfef23dc7b1ac3b",
        filename="micromamba-x86_64-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/linux-aarch64/micromamba-$version-$build.tar.bz2",
        "d1ce4c3842be0afa8a0319fbf88d147a613dd16ddd817bd7eee64e8a35bff0a2",
        filename="micromamba-aarch64-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/linux-ppc64le/micromamba-$version-$build.tar.bz2",
        "c78c9606a6c604a87ad7ffdeb8bd8c8e66fa5ddd7693ed09268478331b11b576",
        filename="micromamba-powerpc64le-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/osx-64/micromamba-$version-$build.tar.bz2",
        "f426ea774765b52dccf2edbb8b261fded226b903a9e925c63807850733ca19b7",
        filename="micromamba-x86_64-apple-darwin14.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/osx-arm64/micromamba-$version-$build.tar.bz2",
        "91fc0681808520c20d7af59f310a34316e12e84b9279b48afac0f20084bec8f0",
        filename="micromamba-aarch64-apple-darwin20.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/win-64/micromamba-$version-$build.tar.bz2",
        "5e51be4efa4f0e421077d153cec52c0868863a9e3c28198b92afe1c2150d83d8",
        filename="micromamba-x86_64-w64-mingw32.tar.bz2"),
]

# Bash recipe for building across all platforms
script = raw"""
# unpack the tarball (BinaryBuilder does not natively support bzip2 so we do this ourselves)
cd $WORKSPACE/srcdir
mkdir micromamba
cd micromamba
tar xjf ../micromamba-$target.tar.bz2

# install the binary
if [[ $target = *-w64-* ]]; then
    install -Dvm 755 Library/bin/micromamba.exe "${bindir}/micromamba.exe"
else
    install -Dvm 755 bin/micromamba "${bindir}/micromamba"
fi

# install the licenses
install_license info/licenses/*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("micromamba", :micromamba),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6", lazy_artifacts=true)
