# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MKL_Headers"
version = v"2023.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2023.1.0/download/win-32/mkl-include-2023.1.0-intel_46356.tar.bz2",
        "81f7efd96cb35ee24ea79011bb12dd038113417c94afa9718a7f45c16b81d559";
        unpack_target = "mkl-include-i686-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2023.1.0/download/win-64/mkl-include-2023.1.0-intel_46356.tar.bz2",
        "19eb554a8c9c75325e26f4f4a8b9b80538d420016065d5ec918fd9c10354c96b";
        unpack_target = "mkl-include-x86_64-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2023.1.0/download/linux-32/mkl-include-2023.1.0-intel_46342.tar.bz2",
        "a6aa2335954fc2ffb0e3e8a5580a101f955061b2086f1b408c7af7827f799a2e";
        unpack_target = "mkl-include-i686-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2023.1.0/download/linux-64/mkl-include-2023.1.0-intel_46342.tar.bz2",
        "b24d12a8e18ba23de5c659a33fb184a7ac6019d4b159e78f628d7c8de225f77a";
        unpack_target = "mkl-include-x86_64-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2023.1.0/download/osx-64/mkl-include-2023.1.0-intel_43558.tar.bz2",
        "f7522e05e61d083e06a802d864c3cefcac8b7bcca35fd08b6cb95a2691808e43";
        unpack_target = "mkl-include-x86_64-apple-darwin14"
    )
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mkl-include-$target
if [[ $target == *-mingw* ]]; then
    rsync -av Library/include/ ${includedir}
else
    rsync -av include/ ${includedir}
fi
install_license info/licenses/*.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    FileProduct("include/mkl.h", :include_mkl_h),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.0")
