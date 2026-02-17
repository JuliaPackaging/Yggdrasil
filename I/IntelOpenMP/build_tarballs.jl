using BinaryBuilder

name = "IntelOpenMP"
version = v"2025.2.0"

sources = [
    # Main OpenMP files
    # Files from the PyPi package: https://pypi.org/project/intel-openmp/#files
    FileSource("https://files.pythonhosted.org/packages/bc/37/bab8e9283407798d8782f4d9b374436e51c7a297e1b6dc05073df550c010/intel_openmp-2025.2.0-py2.py3-none-win_amd64.whl",
               "1710356ae0db744ca028ed380759a2007548ad1819f743be9d675603cb127377"; filename="intel_openmp-x86_64-w64-mingw32.whl"),
    FileSource("https://files.pythonhosted.org/packages/39/17/45e67730f8757a00d665095338b21ca04890d2a3d52a44d725fb5393a044/intel_openmp-2025.2.0-py2.py3-none-manylinux_2_28_x86_64.whl",
               "57f52a5f374e70dce56591ab23bf274252a68128d5b8de8f897f3683f65374c8"; filename="intel_openmp-x86_64-linux-gnu.whl"),
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
