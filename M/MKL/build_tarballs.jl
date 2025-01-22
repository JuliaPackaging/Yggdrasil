using BinaryBuilder, Pkg

name = "MKL"
version = v"2025.0.1"
version_intel_openmp = v"2025.0.4"

sources = [
    FileSource("https://files.pythonhosted.org/packages/82/af/17d96670517ce773521ddd10c6f7752b4a2ffe34609dc367d5bd79425948/mkl-2025.0.1-py2.py3-none-win_amd64.whl",
               "5b7ee0dd14038ea1e1b0eb484f3a883b50aa0130da5d31e8734b960218eb4255"; filename="mkl-x86_64-w64-mingw32.whl"),
    FileSource("https://files.pythonhosted.org/packages/bd/d7/a86e897657596eaadc0f76b1dcde823451cdc4877fc39a8211a47f862202/mkl-2025.0.1-py2.py3-none-manylinux_2_28_x86_64.whl",
               "581b3de496bd004ab2d2bd38775bbcc885303270687940848a19747cce45d47b"; filename="mkl-x86_64-linux-gnu.whl"),
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
        target="${lib%.2}"
        ln -s "${libdir}/$lib" "${libdir}/$target"
    done
fi
cd $WORKSPACE/srcdir
install_license mkl-${target}/mkl-2025.0.1.dist-info/LICENSE.txt
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
