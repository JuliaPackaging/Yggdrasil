# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MKL_Headers"
version = v"2022.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2022.0.1/download/linux-64/mkl-include-2022.0.1-intel_117.tar.bz2",
        "e664eb639faf03d5a4e76b435deb28a67ef7f59f3c55adaeeef771a7c94b56e3";
        unpack_target = "mkl-include-x86_64-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2022.0.1/download/linux-32/mkl-include-2022.0.1-intel_117.tar.bz2",
        "411f636d3e95f75453de80a5574273454b67181c7c30d3276c6cb18a91ef3eeb";
        unpack_target = "mkl-include-i686-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2022.0.0/download/osx-64/mkl-include-2022.0.0-intel_105.tar.bz2",
        "d7aa8f0c7904045c6f569462c0d04cc34250ee991855f5a3ab2fba8bbc5a0d81";
        unpack_target = "mkl-include-x86_64-apple-darwin14"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2022.0.0/download/win-32/mkl-include-2022.0.0-intel_115.tar.bz2",
        "2d9999a92959be25b5dabbd5b69a4b7f738b87215254c776d59c6b2f8b2addf3";
        unpack_target = "mkl-include-i686-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2022.0.0/download/win-64/mkl-include-2022.0.0-intel_115.tar.bz2",
        "eb8f6187d8e4ded8c48b701d00658ef49adc2180e42f1ff52f43c1fecc79a870";
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
