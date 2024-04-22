# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MKL_Headers"
version = v"2024.1.0"

# Collection of sources required to complete build
sources = [
    # Archives for the headers
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2024.1.0/download/win-32/mkl-include-2024.1.0-intel_692.tar.bz2",
        "8994e1c5b5599934e83eb964a136be98dc5a6355f3f5b35cab44cdc0e8b970dd";
        unpack_target = "mkl-include-i686-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2024.1.0/download/win-64/mkl-include-2024.1.0-intel_692.tar.bz2",
        "28229844aa6c19870531452e5805ab876da4a5df896a9e753e6b481da2d389cb";
        unpack_target = "mkl-include-x86_64-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2024.1.0/download/linux-32/mkl-include-2024.1.0-intel_691.tar.bz2",
        "88529f8bea2498e88b2cf8dc7aa3735f46f348cf5047006dfc6455f8e2bbdd30";
        unpack_target = "mkl-include-i686-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2024.1.0/download/linux-64/mkl-include-2024.1.0-intel_691.tar.bz2",
        "e36b2e74f5c28ff91565abe47a09dc246c9cf725e0d05b5fb08813b4073ea68b";
        unpack_target = "mkl-include-x86_64-linux-gnu"
    ),

    # Archives for the CMake/pkgconfig files
    ArchiveSource(
        "https://anaconda.org/intel/mkl-devel/2024.1.0/download/win-32/mkl-devel-2024.1.0-intel_692.tar.bz2",
        "845156ebe08b1d3ac519da1a56d1b98a6f818158eaa88bd4bbaebb9b28aab6cd";
        unpack_target = "mkl-devel-i686-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-devel/2024.1.0/download/win-64/mkl-devel-2024.1.0-intel_692.tar.bz2",
        "d656781f53513be1cde1d33fd84fcd43a746453347afc2fcf1f61218b2d08783";
        unpack_target = "mkl-devel-x86_64-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-devel/2024.1.0/download/linux-32/mkl-devel-2024.1.0-intel_691.tar.bz2",
        "2145f2ae4f383cc46cf4e5f516b7709f727d21865f21d445454c52175c8fafd1";
        unpack_target = "mkl-devel-i686-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-devel/2024.1.0/download/linux-64/mkl-devel-2024.1.0-intel_691.tar.bz2",
        "def8ca30d0560a712e5f010f26da26d723c6bc9148124d8a63f6d2fb64fd3e38";
        unpack_target = "mkl-devel-x86_64-linux-gnu"
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
