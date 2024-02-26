# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Note: 2024.0.0 has already been built, but 2023.2.0 is being built to fix a bug in the packaging where the CMake/pkgconfig scripts were missing.
# When updating to the next 2024.x.x release, the following must be done again (in addition to updating the sources):
# * Bump the Julia compat to 1.6
# * Remove the macos x86_64 platform and source files

name = "MKL_Headers"
version = v"2023.2.0"

# Collection of sources required to complete build
sources = [
    # Archives for the headers
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2023.2.0/download/win-32/mkl-include-2023.2.0-intel_49496.tar.bz2",
        "0ed907ecc2eaae0ed8c280814392b5b80cc19df78838d9688273a12bd72c7bf8";
        unpack_target = "mkl-include-i686-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2023.2.0/download/win-64/mkl-include-2023.2.0-intel_49496.tar.bz2",
        "daa93c899e6c7627232fa60e67a2b6079cd29752e8ba1251ae895a57e51defa7";
        unpack_target = "mkl-include-x86_64-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2023.2.0/download/linux-32/mkl-include-2023.2.0-intel_49495.tar.bz2",
        "b4433c6839bb7f48951b2dcf409dec7306aee3649c539ee0513d8bfb1a1ea283";
        unpack_target = "mkl-include-i686-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2023.2.0/download/linux-64/mkl-include-2023.2.0-intel_49495.tar.bz2",
        "0dfb6ca3c17d99641f20877579c78155cf95aa0b22363bcc91b1d57df4646318";
        unpack_target = "mkl-include-x86_64-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2023.2.0/download/osx-64/mkl-include-2023.2.0-intel_49499.tar.bz2",
        "c3940a33498df821821c28dc292f7d7a739b11892856fd9fbbc3de5cf0990b00";
        unpack_target = "mkl-include-x86_64-apple-darwin14"
    ),

    # Archives for the CMake/pkgconfig files
    ArchiveSource(
        "https://anaconda.org/intel/mkl-devel/2023.2.0/download/win-32/mkl-devel-2023.2.0-intel_49496.tar.bz2",
        "15653969e64579e7bfb098fcc3e994590b6f7f7fcf9f2ac6447884e8f0ffb027";
        unpack_target = "mkl-devel-i686-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-devel/2023.2.0/download/win-64/mkl-devel-2023.2.0-intel_49496.tar.bz2",
        "caaf632783636e8434216f37978b0942e0aa18c9fd3a4bb4a0444aa48ac07323";
        unpack_target = "mkl-devel-x86_64-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-devel/2023.2.0/download/linux-32/mkl-devel-2023.2.0-intel_49495.tar.bz2",
        "09302cd45ff9252e862abe8bc01cefc1f4afa8339237129f847620784f1fd93e";
        unpack_target = "mkl-devel-i686-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-devel/2023.2.0/download/linux-64/mkl-devel-2023.2.0-intel_49495.tar.bz2",
        "f3e2b7063b28b280602fea4005408ee74cf6a376bc99c0e05fc67531f2c03ace";
        unpack_target = "mkl-devel-x86_64-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-devel/2023.2.0/download/osx-64/mkl-devel-2023.2.0-intel_49499.tar.bz2",
        "0f1f7da2fb79d40257c9a15496c84036771cb265c6e3c82ed8b5852c64bdeed0";
        unpack_target = "mkl-devel-x86_64-apple-darwin14"
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

cd $WORKSPACE/srcdir/mkl-devel-$target
mkdir -p ${libdir}
if [[ $target == *-mingw* ]]; then
    # These toolchain files must still go inside the lib folder, not the ${libdir} folder
    rsync -av Library/lib/ $WORKSPACE/destdir/lib
else
    rsync -av lib/ ${libdir}
fi
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
