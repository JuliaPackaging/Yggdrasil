using BinaryBuilder

name = "IntelOpenMP"
version = v"2023.1.0"

sources = [
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2023.1.0/download/win-32/intel-openmp-2023.1.0-intel_46319.tar.bz2",
                  "49175ba7b457bf1e0fd1d85bdc5c0b91096212b56c008960cd617d435511be74"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2023.1.0/download/win-64/intel-openmp-2023.1.0-intel_46319.tar.bz2",
                  "e38a929816dbaa01ff338b4f0792ce9034f9c6497905dd479d9ee580065d9967"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2023.1.0/download/linux-32/intel-openmp-2023.1.0-intel_46305.tar.bz2",
                  "138930b868b1ccc19d5976e28580deb5e8abb95d940dab7b0196646d1953fa24"; unpack_target="i686-linux-gnu"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2023.1.0/download/linux-64/intel-openmp-2023.1.0-intel_46305.tar.bz2",
                  "5b56c0d16860d678d082f38c7349e52d00969ea1ca788027880529c3c03a2b68"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2023.1.0/download/osx-64/intel-openmp-2023.1.0-intel_43547.tar.bz2",
                  "b2e60feb9fe22c59cdde8996e83b3a5c60e72748903e23fa05f6f2e26233641a"; unpack_target="x86_64-apple-darwin14"),
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
install_license ${target}/info/licenses/*.txt
"""

# The products that we will ensure are always built
products = [
    LibraryProduct(["libiomp5", "libiomp5md"], :libiomp),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)
include("../../fancy_toys.jl")

no_autofix_platforms = [Platform("x86_64", "macos")]
autofix_platforms = [Platform("i686", "windows"), Platform("x86_64", "windows"), Platform("x86_64", "linux"), Platform("i686", "linux")]

if any(should_build_platform.(triplet.(no_autofix_platforms)))
    # Need to disable autofix: setting the soname on libiomp breaks it:
    # https://github.com/JuliaMath/FFTW.jl/pull/178#issuecomment-761904389
    build_tarballs(non_reg_ARGS, name, version, sources, script, no_autofix_platforms, products, dependencies; autofix = false)
end
if any(should_build_platform.(triplet.(autofix_platforms)))
    # Let's try to run autofix on the other platforms
    build_tarballs(ARGS, name, version, sources, script, autofix_platforms, products, dependencies)
end
