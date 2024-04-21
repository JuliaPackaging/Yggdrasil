using BinaryBuilder

name = "IntelOpenMP"
version = v"2024.1.0"

sources = [
    # Main OpenMP files
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2024.1.0/download/win-32/intel-openmp-2024.1.0-intel_964.tar.bz2",
                  "fff7a16f808a1aa5f4a9aa05ca9e28045895b0bcf0a9b9a64cfeed70f7ca647f"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2024.1.0/download/win-64/intel-openmp-2024.1.0-intel_964.tar.bz2",
                  "862eec5374464534149ba203f061abd3bb69a1240e7257d560f2a86888fb780e"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2024.1.0/download/linux-32/intel-openmp-2024.1.0-intel_963.tar.bz2",
                  "46185591a72a0d959e1ac5333bc749f97c86c3f03785f2053cdafd7bd37d92ec"; unpack_target="i686-linux-gnu"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2024.1.0/download/linux-64/intel-openmp-2024.1.0-intel_963.tar.bz2",
                  "6ab48343ca3c15768c33ca50ba2f0266e8d300b6755a685ae1aa5149fbe008e9"; unpack_target="x86_64-linux-gnu"),

    # Archive for Windows linker file, only available for win64 currently
    ArchiveSource("https://anaconda.org/intel/dpcpp_impl_win-64/2024.1.0/download/win-64/dpcpp_impl_win-64-2024.1.0-intel_964.tar.bz2",
                  "3c72809c39e6b1a97a0b4e234705c33b37b0ca0dc4315d0b47f16fd878f7164c"; unpack_target="x86_64-w64-mingw32-dpcpp"),
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
