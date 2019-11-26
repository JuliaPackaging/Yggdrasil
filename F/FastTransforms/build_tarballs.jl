using BinaryBuilder

# Collection of sources required to build FastTransforms
name = "FastTransforms"
version = v"0.2.12"
sources = [
    "https://github.com/MikaelSlevinsky/FastTransforms/archive/v$(version).tar.gz" =>
    "640c39f148d757760c2658d96ae86e46a568cb3971410c736ce85b0725f28e8a",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/FastTransforms-*
if [[ ${target} == x86_64-w64-mingw32 ]]; then
    export CFLAGS="-mavx -fno-asynchronous-unwind-tables "
else
    export CFLAGS="-mavx "
fi
if [[ ${nbits} == 64 ]]; then
    SYMBOL_DEFS=()
    SYMBOLS=(dgemm dtrmm dtrmv dtrsm sgemm strmm strsm)
    for sym in ${SYMBOLS[@]}; do
        SYMBOL_DEFS+=("-Dcblas_${sym}=cblas_${sym}64_")
    done
    CFLAGS+=${SYMBOL_DEFS[@]}
    BLAS=openblas64_
else
    BLAS=openblas
fi
make lib CC=gcc FT_PREFIX=${prefix} FT_BLAS=${BLAS} FT_FFTW_WITH_COMBINED_THREADS=1
mv -f libfasttransforms.${dlext} ${libdir}
"""

platforms = expand_gfortran_versions(supported_platforms())
platforms = [p for p in platforms if BinaryBuilder.proc_family(p) == :intel]

# The products that we will ensure are always built
products = [
    LibraryProduct("libfasttransforms", :libfasttransforms),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "CompilerSupportLibraries_jll";
    "FFTW_jll";
    "MPFR_jll";
    "OpenBLAS_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
