# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MKL_Headers"
version = v"2023.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2024.0.0/download/win-32/mkl-include-2024.0.0-intel_49657.tar.bz2",
        "9359c55d2fcf26b7cd879362504416fb5cd924af07f29e763c9dab980c19f783";
        unpack_target = "mkl-include-i686-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2024.0.0/download/win-64/mkl-include-2024.0.0-intel_49657.tar.bz2",
        "8f4215100f4360017721ce154c0fd9fa1628c78ac733e4cbd863d1bf3ab4f21d";
        unpack_target = "mkl-include-x86_64-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2024.0.0/download/linux-32/mkl-include-2024.0.0-intel_49656.tar.bz2",
        "6a55c84a4a3088b36d507ee6de019c52c164a7756f4e14275cf0bf16aac9e87d";
        unpack_target = "mkl-include-i686-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-include/2024.0.0/download/linux-64/mkl-include-2024.0.0-intel_49656.tar.bz2",
        "fcbdf5d4197f18fb91fa1d9648f35a45628cc1131ff58c83dcbafe2767490571";
        unpack_target = "mkl-include-x86_64-linux-gnu"
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
