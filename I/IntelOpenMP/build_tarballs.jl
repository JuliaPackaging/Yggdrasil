using BinaryBuilder

name = "IntelOpenMP"
version = v"2018.0.3"

sources = [
    ArchiveSource("https://anaconda.org/intel/openmp/2018.0.3/download/win-32/openmp-2018.0.3-intel_0.tar.bz2",
                  "86ed603332ed7b4004e8a474943468589b222ef16d0d9aaf3ebb4ceaf743a39d"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/openmp/2018.0.3/download/win-64/openmp-2018.0.3-intel_0.tar.bz2",
                  "0aee3d9debb8b1c2bb9a202b780c2b2d2179e4cee9158f7d0ad46125cf6f3fa2"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/openmp/2018.0.3/download/osx-64/openmp-2018.0.3-intel_0.tar.bz2",
                  "110b94d5ff3c4df66fc89030c30ad42378da02817b3962f14cb5c268f9d94dae"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("https://anaconda.org/intel/openmp/2018.0.3/download/linux-32/openmp-2018.0.3-intel_0.tar.bz2",
                  "f06edc0c52337658fd4b780d0b5c704b0ffb1c156dced7f5038c1ebbda3d891b"; unpack_target="i686-linux-gnu"),
    ArchiveSource("https://anaconda.org/intel/openmp/2018.0.3/download/linux-64/openmp-2018.0.3-intel_0.tar.bz2",
                  "cae3ef59d900f12c723a3467e7122b559f0388c08c40c332da832131c024409b"; unpack_target="x86_64-linux-gnu"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p "${libdir}"
    if [[ ${target} == *mingw* ]]; then
    mv ${target}/Library/bin/* "${libdir}/."
else
    mv ${target}/lib/* "${libdir}/."
fi
install_license ${target}/info/*.txt
"""

platforms = [
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
    Platform("x86_64", "macos"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libiomp5", "libiomp5md"], :libiomp),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
