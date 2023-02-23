# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "micromamba"
version = v"1.3.1"
build = "0"

# Collection of sources required to build micromamba
# These are actually just the conda packages for each platform
sources = [
    FileSource("https://conda.anaconda.org/conda-forge/linux-64/micromamba-$version-$build.tar.bz2",
        "44fdd6c8805a8456d3ecbe8ae05c1904d3c44f022361d8f7027d344ebf55c618",
        filename="micromamba-x86_64-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/linux-aarch64/micromamba-$version-$build.tar.bz2",
        "e2d7c2ba7484fc6c7c27462222cbb8b762e496c1bc113bfa0267dc458a8d6f8b",
        filename="micromamba-aarch64-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/linux-ppc64le/micromamba-$version-$build.tar.bz2",
        "87bd7b169c1b752f21201195b9f6d333705bfd3201890c5b24dcfa16db0300b5",
        filename="micromamba-powerpc64le-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/osx-64/micromamba-$version-$build.tar.bz2",
        "f4da280b281d64e2cf7e381dcc4655cfd093cd27e510290d9bacae739fd5286a",
        filename="micromamba-x86_64-apple-darwin14.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/osx-arm64/micromamba-$version-$build.tar.bz2",
        "6bcec771f4f76a0b35d931e0ac78cf42b999ac7665fd63809780362f766fe8a9",
        filename="micromamba-aarch64-apple-darwin20.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/win-64/micromamba-$version-$build.tar.bz2",
        "46243de1ff04812866d897f2a17bdee23c075f20ef98f4196803f7be6047ad0a",
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
