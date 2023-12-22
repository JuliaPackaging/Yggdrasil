# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MKL_Headers"
version = v"2024.0.0"

# Collection of sources required to complete build
sources = [
    # Archives for the headers
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

    # Archives for the CMake/pkgconfig files
    ArchiveSource(
        "https://anaconda.org/intel/mkl-devel/2024.0.0/download/win-32/mkl-devel-2024.0.0-intel_49657.tar.bz2",
        "6d7ce2dd7660e31251621e4b5d22049e0bace07b650831db8b4e7b1a78981dc5";
        unpack_target = "mkl-devel-i686-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-devel/2024.0.0/download/win-64/mkl-devel-2024.0.0-intel_49657.tar.bz2",
        "05e43480b2bf0a4f6e6f3208aa88e613b0b44e6639c7c5e52bef518193364dba";
        unpack_target = "mkl-devel-x86_64-w64-mingw32"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-devel/2024.0.0/download/linux-32/mkl-devel-2024.0.0-intel_49656.tar.bz2",
        "6e57d8f98ab904b55d8e5bb810c06d8d889308f774a6ec08cac76c53b6024256";
        unpack_target = "mkl-devel-i686-linux-gnu"
    ),
    ArchiveSource(
        "https://anaconda.org/intel/mkl-devel/2024.0.0/download/linux-64/mkl-devel-2024.0.0-intel_49656.tar.bz2",
        "f6c37ade3153a0a98cf1f50346af32be1b87c4c3cb09e4f7b94dcb77b4896bd7";
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
