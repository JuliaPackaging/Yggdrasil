using BinaryBuilder

name = "IntelOpenMP"
version = v"2025.0.4"

sources = [
    # Main OpenMP files
    FileSource("https://files.pythonhosted.org/packages/51/36/1074001dc5a5add3f445dc1d44aecbb239e60fef8269b9c420d731d002d2/intel_openmp-2025.0.4-py2.py3-none-win_amd64.whl",
               "9dd9c2918158bd19395f28ee2e4b91c00bd86fe45b627e765f611478c7c2c173"; filename="intel_openmp-x86_64-w64-mingw32.whl"),
    FileSource("https://files.pythonhosted.org/packages/a2/f9/d35767b6ae062e841c20beee56151c914c733dba1a0ba5996c2fc6792a90/intel_openmp-2025.0.4-py2.py3-none-manylinux_2_28_x86_64.whl",
               "bf31d1cbf3f857b90a7e3c1caab75a546445845e14fd24439e81a70bcbc8d783"; filename="intel_openmp-x86_64-linux-gnu.whl"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
unzip -d intel_openmp-$target intel_openmp-$target.whl

if [[ ${target} == *x86_64-w64-mingw* ]]; then
    install -Dvm 755 intel_openmp-${target}/intel_openmp-*.data/data/Library/bin/* -t "${libdir}"

    # These import libraries go inside the actual lib folder, not the bin folder with the DLLs
    install -Dv intel_openmp-${target}/intel_openmp-*.data/data/Library/lib/libiomp5md.lib -t "${prefix}/lib/"
    install -Dv intel_openmp-${target}/intel_openmp-*.data/data/Library/lib/libiompstubs5md.lib -t "${prefix}/lib/"
fi
if [[ ${target} == *x86_64-linux-gnu* ]]; then
    install -Dvm 755 intel_openmp-${target}/intel_openmp-*.data/data/lib/*.${dlext} -t "${libdir}"
fi
install_license intel_openmp-${target}/intel_openmp-*.dist-info/LICENSE.txt
install_license intel_openmp-${target}/intel_openmp-*.data/data/share/doc/compiler/licensing/openmp/third-party-programs.txt
"""

# The products that we will ensure are always built
products = [
    LibraryProduct(["libiomp5", "libiomp5md"], :libiomp),
]

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "windows"),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; lazy_artifacts=true, julia_compat="1.6")
