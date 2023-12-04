using BinaryBuilder

name = "IntelOpenMP"
version = v"2024.0.0"

sources = [
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2024.0.0/download/win-32/intel-openmp-2024.0.0-intel_49840.tar.bz2",
                  "7b94dd0d65c8fbb76f0e2ab207731ae1cf6cf0ab3678e79d9bcfae56b5fb7fe6"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2024.0.0/download/win-64/intel-openmp-2024.0.0-intel_49840.tar.bz2",
                  "a971532e9a397ec2907d079183f2852d907e42b8ac7616e53e1d3dd664903721"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2024.0.0/download/linux-32/intel-openmp-2024.0.0-intel_49819.tar.bz2",
                  "f3e8e6fea77e8206ca32727fd59fb55a496f70a0f9942d0216b9ba5789a0a9b4"; unpack_target="i686-linux-gnu"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2024.0.0/download/linux-64/intel-openmp-2024.0.0-intel_49819.tar.bz2",
                  "feee49a26abc74ef0b57cfb6f521b427d6a93e7d8293d30e941b70d5fd0ab2d9"; unpack_target="x86_64-linux-gnu"),
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
