# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "micromamba"
version = v"1.5.12"
build = "0"

# Collection of sources required to build micromamba
# These are actually just the conda packages for each platform
sources = [
    FileSource("https://conda.anaconda.org/conda-forge/linux-64/micromamba-$version-$build.tar.bz2",
        "c8d0e74cdf31349b98af7a57b0faed1468c9ebb908ca95fc8fb6df2597e8a76f",
        filename="micromamba-x86_64-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/linux-aarch64/micromamba-$version-$build.tar.bz2",
        "85248cad98ea560de7dfdb98ed2e2f729c69150b59bedf0bdd62ff871b9c8a53",
        filename="micromamba-aarch64-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/linux-ppc64le/micromamba-$version-$build.tar.bz2",
        "7c263176667c5baf201cce54df5d41d4959ce00374cf9f19e601f864e42106ed",
        filename="micromamba-powerpc64le-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/osx-64/micromamba-$version-$build.tar.bz2",
        "ada5422d1aa75282a2028ff86005460351f73680ff3a38dd387296b86568e654",
        filename="micromamba-x86_64-apple-darwin14.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/osx-arm64/micromamba-$version-$build.tar.bz2",
        "6a0c105246f65ffd063e04c1f29aaebf8f3b07f06178de3a13993572e5b3ffa8",
        filename="micromamba-aarch64-apple-darwin20.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/win-64/micromamba-$version-$build.tar.bz2",
        "078a87f3f009586fed9450b085ed4801bf2aab552bb88da72d881db2cee40f89",
        filename="micromamba-x86_64-w64-mingw32.tar.bz2"),
]

# Bash recipe for building across all platforms
script = raw"""
# Unpack only the tarball for our target
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
install_license info/licenses/*.txt
install_license info/licenses/mamba/*
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
