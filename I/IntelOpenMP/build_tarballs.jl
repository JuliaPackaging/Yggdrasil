using BinaryBuilder

name = "IntelOpenMP"
version = v"2024.0.2"

sources = [
    # Main OpenMP files
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2024.0.2/download/win-32/intel-openmp-2024.0.2-intel_49896.tar.bz2",
                  "437439357a3333104f873efb4e9fd932af12fdcbb6e14c5bc45835ece325b767"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2024.0.2/download/win-64/intel-openmp-2024.0.2-intel_49896.tar.bz2",
                  "85a0795a2598d5a040b620796b83bf32ea86638564d174ddb8776df0ce6bf55e"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2024.0.2/download/linux-32/intel-openmp-2024.0.2-intel_49895.tar.bz2",
                  "20940af6206994f3a6b58404ade710e2b38de659e3998fb51d25271090267de8"; unpack_target="i686-linux-gnu"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2024.0.2/download/linux-64/intel-openmp-2024.0.2-intel_49895.tar.bz2",
                  "ed4eec1642bfd613bfe2a4fd0e79ac4cfab2b623f71d7e6b2ea553962972ab63"; unpack_target="x86_64-linux-gnu"),

    # Archive for Windows linker file, only available for win64 currently
    ArchiveSource("https://anaconda.org/intel/dpcpp_impl_win-64/2024.0.2/download/win-64/dpcpp_impl_win-64-2024.0.2-intel_49896.tar.bz2",
                  "4516779ade366aae8a82d01aa1718e73bfa1433c03bf15e845c227c253ab4840"; unpack_target="x86_64-w64-mingw32-dpcpp"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p "${libdir}"
if [[ ${target} == *i686-w64-mingw* ]]; then
    mv ${target}/bin32/* "${libdir}/."
fi
if [[ ${target} == *x86_64-w64-mingw* ]]; then
    mv ${target}/bin/* "${libdir}/."

    # These import libraries go inside the actual lib folder, not the bin folder with the DLLs
    mkdir -p $WORKSPACE/destdir/lib
    cp ${target}-dpcpp/Library/lib/libiomp5md.lib "$WORKSPACE/destdir/lib/"
    cp ${target}-dpcpp/Library/lib/libiompstubs5md.lib "$WORKSPACE/destdir/lib/"
fi
if [[ ${target} == *i686-linux-gnu* ]]; then
    mv ${target}/lib32/* "${libdir}/."
fi
if [[ ${target} == *x86_64-linux-gnu* ]]; then
    mv ${target}/lib/* "${libdir}/."
fi
install_license ${target}/info/licenses/*.txt
"""

# The products that we will ensure are always built
products = [
    LibraryProduct(["libiomp5", "libiomp5md"], :libiomp),
]

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
