# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "micromamba"
version = v"0.25.1"

# Collection of sources required to build micromamba
# These are actually just the conda packages for each platform
sources = [
    FileSource("https://micro.mamba.pm/api/micromamba/linux-64/$version",
        "2d8ab91435ea75e4b76412795742b6a17ff25f6d7081a9411a1bc96688e1f7d1",
        filename="micromamba-x86_64-linux-gnu.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/linux-aarch64/$version",
        "069937fc13c42b3963f1bbe991ad921cdcd75f07771b9a6468c92b66d9b298f6",
        filename="micromamba-aarch64-linux-gnu.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/linux-ppc64le/$version",
        "0f5be296570c93317ff22af8b586cf07bd4a96c5e30b323b53fa0970755c2c31",
        filename="micromamba-powerpc64le-linux-gnu.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/osx-64/$version",
        "bd80ed9cb39748a40ae7dfd124aa18e453bf4793e281daf687710c81272e8be1",
        filename="micromamba-x86_64-apple-darwin14.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/osx-arm64/$version",
        "b39fb2f9f2bed41c5ad885f41f49ba751a4ba5ee01ee96ca8293a84aa603d1b2",
        filename="micromamba-aarch64-apple-darwin20.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/win-64/$version",
        "ed3b12b747f05a630198d3a8a8f7120bde22ae9033cb62af95d6f3df57fe9b0c",
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
