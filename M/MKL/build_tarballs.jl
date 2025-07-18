using BinaryBuilder, Pkg

name = "MKL"
version = v"2025.2.0"
version_intel_openmp = v"2025.2.0"

sources = [
    # Files from the PyPi package https://pypi.org/project/mkl/#files
    FileSource("https://files.pythonhosted.org/packages/91/ae/025174ee141432b974f97ecd2aea529a3bdb547392bde3dd55ce48fe7827/mkl-2025.2.0-py2.py3-none-win_amd64.whl",
               "b6ec153e4a073421dbb52ef99c7be97e66cde0272e4a1e3569b090b6f0130253"; filename="mkl-x86_64-w64-mingw32.whl"),
    FileSource("https://files.pythonhosted.org/packages/46/7b/f5b1b84eb0a2a6e145fc31b4e6b1c59690dcb088734197da8f299caf7c67/mkl-2025.2.0-py2.py3-none-manylinux_2_28_x86_64.whl",
               "974b4e222cc94e8d3b67213a361c8ac25d432cc4fccc5f2f00aa15c4e67cc203"; filename="mkl-x86_64-linux-gnu.whl"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
unzip -d mkl-$target mkl-$target.whl

if [[ ${target} == *x86_64-w64-mingw* ]]; then
    install -Dvm 755 mkl-${target}/mkl-*.data/data/Library/bin/* -t "${libdir}"
fi
if [[ ${target} == *x86_64-linux-gnu* ]]; then
    install -Dvm 755 mkl-${target}/mkl-*.data/data/lib/* -t "${libdir}"
    cd mkl-${target}/mkl-*.data/data/lib
    for lib in *.so.2; do
        symlink="${lib%.2}"
        ln -s "${libdir}/$lib" "${libdir}/$symlink"
    done
fi
install_license $WORKSPACE/srcdir/mkl-${target}/mkl-*.dist-info/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
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
    Dependency(PackageSpec(name="IntelOpenMP_jll", uuid="1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"); compat="$version_intel_openmp"),
    Dependency(PackageSpec(name="oneTBB_jll", uuid="1317d2d5-d96f-522e-a858-c73665f53c3e")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; lazy_artifacts=true, julia_compat="1.6")
