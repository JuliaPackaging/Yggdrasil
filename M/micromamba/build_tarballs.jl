# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "micromamba"
version = v"1.4.0"
build = "0"

# Collection of sources required to build micromamba
# These are actually just the conda packages for each platform
sources = [
    FileSource("https://conda.anaconda.org/conda-forge/linux-64/micromamba-$version-$build.tar.bz2",
        "4520263a7377cb1f420e11f542006ba49c063d9c6d34d1be397ca7348777e735",
        filename="micromamba-x86_64-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/linux-aarch64/micromamba-$version-$build.tar.bz2",
        "7c70e92a75584215813411a76066290ac2b92d0bb39660c89285e7f226899473",
        filename="micromamba-aarch64-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/linux-ppc64le/micromamba-$version-$build.tar.bz2",
        "b5397b68075958c7afca61ca069d575e234138afbfea0bd5c53f4710324904bc",
        filename="micromamba-powerpc64le-linux-gnu.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/osx-64/micromamba-$version-$build.tar.bz2",
        "f234d8fc2b89fa242bee574862ed8a5291296159f32344fb1e8f341df5c7c84d",
        filename="micromamba-x86_64-apple-darwin14.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/osx-arm64/micromamba-$version-$build.tar.bz2",
        "11d3c11280093a04a3bdb8ea34678701029843b527aad8af67d596221d083582",
        filename="micromamba-aarch64-apple-darwin20.tar.bz2"),
    FileSource("https://conda.anaconda.org/conda-forge/win-64/micromamba-$version-$build.tar.bz2",
        "09dfd50af36bc53040fac893a4727b08f0735fb7e9de62a469630b9af6eeb7cd",
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
