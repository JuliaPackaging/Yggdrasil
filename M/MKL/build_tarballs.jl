using BinaryBuilder, Pkg

name = "MKL"
version = v"2024.0.0"

sources = [
    ArchiveSource("https://anaconda.org/intel/mkl/2024.0.0/download/win-32/mkl-2024.0.0-intel_49657.tar.bz2",
                  "c9418f0c982f6d914f147bf1262a6d4dc631a3a2de61bae92ffc4e8d9e9d4b14"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/mkl/2024.0.0/download/win-64/mkl-2024.0.0-intel_49657.tar.bz2",
                  "5e69fd6314f5ed95da076bdf1a4701aa234dc842d5dfc845d5b2e05e12cd7fcc"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/mkl/2024.0.0/download/linux-32/mkl-2024.0.0-intel_49656.tar.bz2",
                  "0445142acaec7f2371682ddce8016049bff8d2ec015a2431b650f3dc03d14720"; unpack_target="i686-linux-gnu"),
    ArchiveSource("https://anaconda.org/intel/mkl/2024.0.0/download/linux-64/mkl-2024.0.0-intel_49656.tar.bz2",
                  "e02ad8cf2b0d1c18c4c0a6a06cb23ec6dc076678ab1e5bbc55876aa56f390458"; unpack_target="x86_64-linux-gnu"),
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
    LibraryProduct(["libmkl_core", "mkl_core.2"], :libmkl_core),
    LibraryProduct(["libmkl_rt", "mkl_rt.2"], :libmkl_rt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # MKL should use the corresponding version of IntelOpenMP, otherwise there may
    # occasionally be incompatibilities, e.g. x86_64 macOS builds were removed in v2024,
    # using MKL v2023 with IntelOpenMP v2024 would be problematic:
    # <https://github.com/JuliaMath/FFTW.jl/issues/281>.
    Dependency(PackageSpec(name="IntelOpenMP_jll", uuid="1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"); compat=string(version)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; lazy_artifacts=true, julia_compat="1.6")
