using BinaryBuilder

name = "IntelOpenMP"
version = v"2024.2.0"

sources = [
    # Main OpenMP files
    ArchiveSource("https://conda.anaconda.org/intel/win-32/intel-openmp-2024.2.0-intel_978.tar.bz2",
                  "0f050fa361f22a3b7291daf7ec5ac208c6e652977643b2e289169d7475d64244"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://conda.anaconda.org/intel/win-64/intel-openmp-2024.2.0-intel_978.tar.bz2",
                  "44d653f234ae35162ad2211d1281a21c613599e5dd68dd2e1229d27592f784f9"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://conda.anaconda.org/intel/linux-32/intel-openmp-2024.2.0-intel_981.tar.bz2",
                  "38fac9228334cbaf61f1e7b0a70f4083d58a60dfc2e132a62881b976e1cb2301"; unpack_target="i686-linux-gnu"),
    ArchiveSource("https://conda.anaconda.org/intel/linux-64/intel-openmp-2024.2.0-intel_981.tar.bz2",
                  "db46064dbf0dbc096d92d8368ef8172ae335001b81055840c97fcfda3d09d64d"; unpack_target="x86_64-linux-gnu"),

    # Archive for Windows linker file, only available for win64 currently
    ArchiveSource("https://conda.anaconda.org/intel/win-64/dpcpp_impl_win-64-2024.2.0-intel_978.tar.bz2",
                  "e899ae8ef10a5d2656a18cc45615889bffaa9c4f18053f90073dc50ac4586585"; unpack_target="x86_64-w64-mingw32-dpcpp"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p "${libdir}"
if [[ ${target} == *i686-w64-mingw* ]]; then
    mv ${target}/bin32/* "${libdir}/."
fi
if [[ ${target} == *x86_64-w64-mingw* ]]; then
    mv ${target}/Library/bin/* "${libdir}/."

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; lazy_artifacts=true, julia_compat="1.6")
