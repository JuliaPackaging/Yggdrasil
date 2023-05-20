# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "micromamba"
version = v"1.4.3"
build = "0"

# Collection of sources required to build micromamba
# These are actually just the conda packages for each platform
sources = [
    FileSource("https://conda.anaconda.org/conda-forge/linux-64/micromamba-$version-$build.tar.bz2",
        "faf0a6af6d0676050a7ec535a3d10c50c9c03bbf0bb554732151cf62f3417379",
        filename="micromamba-x86_64-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/linux-aarch64/micromamba-$version-$build.tar.bz2",
        "1044323557ea4677c54c2cb643f0f36786da7085e1c2930a9f36521aae686388",
        filename="micromamba-aarch64-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/linux-ppc64le/micromamba-$version-$build.tar.bz2",
        "6157e877bc63f8f3081c0904075ef47952a86106870aa6f94f6116a6e951a50d",
        filename="micromamba-powerpc64le-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/osx-64/micromamba-$version-$build.tar.bz2",
        "36c437a03c7cc72b4366d5225afa86d65e21f5100bd30cdb5b602465e812a02a",
        filename="micromamba-x86_64-apple-darwin14.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/osx-arm64/micromamba-$version-$build.tar.bz2",
        "93dee34f603cc189e9d1ac99ed2938bedd8de81fab350fce128bd453a04bd73b",
        filename="micromamba-aarch64-apple-darwin20.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/win-64/micromamba-$version-$build.tar.bz2",
        "173d2a8dd8e324611fa7331992896ebf7ea2f953c61559c10772ee377af27d05",
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
