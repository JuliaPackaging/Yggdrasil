using BinaryBuilder

name = "IntelOpenMP"
version = v"2023.2.0"

sources = [
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2023.2.0/download/win-32/intel-openmp-2023.2.0-intel_49496.tar.bz2",
                  "8268bb806b8e8b66865599e03fba4075e4bc4d8a377a9143abed04184163c814"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2023.2.0/download/win-64/intel-openmp-2023.2.0-intel_49496.tar.bz2",
                  "e4d26c9e62e8ad62c5c67a0c09a79f102d577215a058f447c296bb104e3bd46d"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2023.2.0/download/linux-32/intel-openmp-2023.2.0-intel_49495.tar.bz2",
                  "6ea678c6e07f044c01809212f24bf8e0bd153ef86fde1a2650b2af9cfc128886"; unpack_target="i686-linux-gnu"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2023.2.0/download/linux-64/intel-openmp-2023.2.0-intel_49495.tar.bz2",
                  "003843e7af21ffa0e872c1227749e92c736e0e5e0c5c32ae0b15aa2a13dc0386"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("https://anaconda.org/intel/intel-openmp/2023.2.0/download/osx-64/intel-openmp-2023.2.0-intel_49499.tar.bz2",
                  "37a86c020df8d5a349d9b5076c1783ab08f8c7f28b40e7a0fba9e4f8dec0fc10"; unpack_target="x86_64-apple-darwin14"),
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
