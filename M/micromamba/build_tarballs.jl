# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "micromamba"
version = v"0.26.0"

# Collection of sources required to build micromamba
# These are actually just the conda packages for each platform
sources = [
    FileSource("https://micro.mamba.pm/api/micromamba/linux-64/$version",
        "404100d70109e1c264abae0a28c85b336e47dc2b82957642373794855a05e86c",
        filename="micromamba-x86_64-linux-gnu.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/linux-aarch64/$version",
        "1413aa95bacc0546b02d54bde8b38c161de571465ccca1107ca303c0cb26a958",
        filename="micromamba-aarch64-linux-gnu.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/linux-ppc64le/$version",
        "51f14e6dd24fb9068002da3ba7ca5193879c208676c55c4f3f2459ee222ca64a",
        filename="micromamba-powerpc64le-linux-gnu.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/osx-64/$version",
        "08b52c26ce58c5c0cb94ed420333a09897c48855ed5ed781f50a2ef7801349d7",
        filename="micromamba-x86_64-apple-darwin14.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/osx-arm64/$version",
        "4989c0a5c94d0917d7e1941036ea3adf3da287c4e8249ac680fc41134210ea60",
        filename="micromamba-aarch64-apple-darwin20.tar.bz2"),
    FileSource("https://micro.mamba.pm/api/micromamba/win-64/$version",
        "862d1cc64fa097d705bafa0cf472b173159f940b40ef77537efca80aa162cab1",
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
