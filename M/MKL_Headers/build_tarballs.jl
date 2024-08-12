# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MKL_Headers"
version = v"2024.2.0"

# Collection of sources required to complete build
sources = [
    # Archives for the headers
    ArchiveSource(
        "https://conda.anaconda.org/intel/win-32/mkl-include-2024.2.0-intel_661.tar.bz2",
        "431feac62519a0d65c85e801d7329cb7caa66ced53a0b4d26f15420d06d1717d";
        unpack_target = "mkl-include-i686-w64-mingw32"
    ),
    ArchiveSource(
        "https://conda.anaconda.org/intel/win-64/mkl-include-2024.2.0-intel_661.tar.bz2",
        "34f5cc20b6d2ab7c82f301b108fa2ac48e1f6c0acd8ad166897fb53184d5c93e";
        unpack_target = "mkl-include-x86_64-w64-mingw32"
    ),
    ArchiveSource(
        "https://conda.anaconda.org/intel/linux-32/mkl-include-2024.2.0-intel_663.tar.bz2",
        "d97e655707590ba38d1240a4f9be3f60df2bc82f3ab5f7b16cf2735d4d9ba401";
        unpack_target = "mkl-include-i686-linux-gnu"
    ),
    ArchiveSource(
        "https://conda.anaconda.org/intel/linux-64/mkl-include-2024.2.0-intel_663.tar.bz2",
        "2e29ca36f199bafed778230b054256593c2d572aeb050389fd87355ba0466d13";
        unpack_target = "mkl-include-x86_64-linux-gnu"
    ),

    # Archives for the CMake/pkgconfig files
    ArchiveSource(
        "https://conda.anaconda.org/intel/win-32/mkl-devel-2024.2.0-intel_661.tar.bz2",
        "db2bdd63f774edaca6cdc23677a5cc7ad390cf2bee362140b80238736483ae8f";
        unpack_target = "mkl-devel-i686-w64-mingw32"
    ),
    ArchiveSource(
        "https://conda.anaconda.org/intel/win-64/mkl-devel-2024.2.0-intel_661.tar.bz2",
        "dd8758a3404d2bf6844463b16a3096820d7f7905bafdc057b9135eccf065e118";
        unpack_target = "mkl-devel-x86_64-w64-mingw32"
    ),
    ArchiveSource(
        "https://conda.anaconda.org/intel/linux-32/mkl-devel-2024.2.0-intel_663.tar.bz2",
        "aabe1d37edc7d5d70891e25328d3bd2d8c9d7c5102cc5b400870164322df3a3c";
        unpack_target = "mkl-devel-i686-linux-gnu"
    ),
    ArchiveSource(
        "https://conda.anaconda.org/intel/linux-64/mkl-devel-2024.2.0-intel_663.tar.bz2",
        "e3c37c75aa870aa8daa32e6cbfa6e34639f7e6fe6a67fc4b34fa2a94a497df15";
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
