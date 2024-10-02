using BinaryBuilder, Pkg

name = "MKL"
version = v"2024.2.0"

sources = [
    ArchiveSource("https://conda.anaconda.org/intel/win-32/mkl-2024.2.0-intel_661.tar.bz2",
                  "fa5f4a74600fcc81b7ecc1c61eac01d365ec0031986f847f435d752b8d059828"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://conda.anaconda.org/intel/win-64/mkl-2024.2.0-intel_661.tar.bz2",
                  "162194f166a22ae2ac9bd7945a99c21e750b0122393a435189f81645d284cfe7"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://conda.anaconda.org/intel/linux-32/mkl-2024.2.0-intel_663.tar.bz2",
                  "e46e0d056e7954a7c84f157acb93a51567c97844593f7469f504751723bfc396"; unpack_target="i686-linux-gnu"),
    ArchiveSource("https://conda.anaconda.org/intel/linux-64/mkl-2024.2.0-intel_663.tar.bz2",
                  "f480deb23179471b5f05de50b06ad984702be25e66d58ef614b804b781a3613e"; unpack_target="x86_64-linux-gnu"),
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
