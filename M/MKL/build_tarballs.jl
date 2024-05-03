using BinaryBuilder, Pkg

name = "MKL"
version = v"2024.1.0"

sources = [
    ArchiveSource("https://anaconda.org/intel/mkl/2024.1.0/download/win-32/mkl-2024.1.0-intel_692.tar.bz2",
                  "7d4cc1172df2caf2465225f571d24e2befe55f8f41d0058e4f12a48985d7cf77"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/mkl/2024.1.0/download/win-64/mkl-2024.1.0-intel_692.tar.bz2",
                  "f301d74eb748064a88ba77a26b5e250066601fdf78f77219f39facf04093af5e"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/mkl/2024.1.0/download/linux-32/mkl-2024.1.0-intel_691.tar.bz2",
                  "44b4bc4a730d3b73e798995a9ef2b2227b89d33b5e099412e322a0f570fd6337"; unpack_target="i686-linux-gnu"),
    ArchiveSource("https://anaconda.org/intel/mkl/2024.1.0/download/linux-64/mkl-2024.1.0-intel_691.tar.bz2",
                  "419f0522a7ffa1133deddaa8eec5d8f9a383993b118cfaa2e897c439200549ef"; unpack_target="x86_64-linux-gnu"),
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
    Dependency("oneTBB_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; lazy_artifacts=true, julia_compat="1.6")
