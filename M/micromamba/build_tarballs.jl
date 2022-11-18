# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "micromamba"
version = v"1.0.0"

# Collection of sources required to build micromamba
# These are actually just the conda packages for each platform
sources = [
    FileSource("https://micro.mamba.pm/api/micromamba/linux-64/$version",
        "41bda425dd9c44b59cc35781c1b4031465c36648791e8598f7826f65ef09e387",
        filename="micromamba-x86_64-linux-gnu.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/linux-aarch64/$version",
        "57934f137d326aaaebfd9788ddd0e112135d33b95a7dd3e9292517ce025b4d5a",
        filename="micromamba-aarch64-linux-gnu.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/linux-ppc64le/$version",
        "196831fad6384fc7520ae2bf2eddaae6b3a256d80f607efb5eb1d97d3cc0c4e0",
        filename="micromamba-powerpc64le-linux-gnu.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/osx-64/$version",
        "2141288a06b520c81724eb1fad2e99395133c7d64ca9c776ae8d6ccc7edfd8e0",
        filename="micromamba-x86_64-apple-darwin14.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/osx-arm64/$version",
        "ffb87b3923a01f22d299d21f8da2b57b0a22bf1be4f59f634f449ffa431d7d18",
        filename="micromamba-aarch64-apple-darwin20.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/win-64/$version",
        "e8b02c5b51eecb71953a460846f37acd6066eb3cef6cd3aebc60835048f37ad3",
        filename="micromamba-x86_64-w64-mingw32.tar.bz2"),
]

# Bash recipe for building across all platforms
script = raw"""
echo target=$target

# unpack the tarball (BinaryBuilder does not natively support bzip2 so we do this ourselves)
cd $WORKSPACE/srcdir
mkdir micromamba
cd micromamba
tar xjf ../micromamba-$target.tar.bz2

# install the binary
mkdir -p $bindir
if [[ $target = *-w64-* ]]; then
    cp Library/bin/micromamba.exe $bindir/micromamba.exe
else
    cp bin/micromamba $bindir/micromamba
fi

# install the licenses
mkdir -p $prefix/share/licenses/micromamba
cp info/licenses/* $prefix/share/licenses/micromamba/
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
