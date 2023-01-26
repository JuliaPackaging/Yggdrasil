# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MKL_Headers"
version = v"2022.2.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2022.2.1/download/linux-64/mkl-include-2022.2.1-intel_16993.tar.bz2",
        "144b4939c875ae52b5479317e73be839f5b26b3b0e2c3a52bd59507bc25be56c";
        unpack_target = "mkl-include-x86_64-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2022.2.1/download/linux-32/mkl-include-2022.2.1-intel_16993.tar.bz2",
        "2deec097b972d7784b26b454169af302a0d4e26cc1d65cbb4ed72baf00a8849e";
        unpack_target = "mkl-include-i686-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2022.2.1/download/osx-64/mkl-include-2022.2.1-intel_15346.tar.bz2",
        "fa14e44b3adbcc156aa7b531c4e83143cf9d31fe990210cb6d5d5456f8a417a8";
        unpack_target = "mkl-include-x86_64-apple-darwin14"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2022.2.1/download/win-32/mkl-include-2022.2.1-intel_19754.tar.bz2",
        "04c3ce3f1e6e23e575f904fbdafd089f3241bf28ca1005b2464d87795295dc50";
        unpack_target = "mkl-include-i686-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2022.2.1/download/win-64/mkl-include-2022.2.1-intel_19754.tar.bz2",
        "675519d77dfbf38bfa3dd94f37d3d1fa9f74b32f089e50123605ff3d45752c44";
        unpack_target = "mkl-include-x86_64-w64-mingw32"
    ),
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
