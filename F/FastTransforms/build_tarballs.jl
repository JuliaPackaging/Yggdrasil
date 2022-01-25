using BinaryBuilder

# Collection of sources required to build FastTransforms
name = "FastTransforms"
version = v"0.5.2"
sources = [
    ArchiveSource("https://github.com/MikaelSlevinsky/FastTransforms/archive/v$(version).tar.gz",
                  "985a0061ab937ef2e611c50e0a22e58e0f563f020464425358a040ef8a413e74"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/FastTransforms-*
if [[ ${target} == x86_64-* ]] || [[ ${target} == i686-* ]]; then
    export MSSE=-msse
    export MSSE2=-msse2
    export MAVX=-mavx
    export MFMA=-mfma
    if [[ ${target} == *-w64-mingw32 ]]; then
        export CFLAGS="-O3 -mavx -fno-asynchronous-unwind-tables "
    else
        export CFLAGS="-O3 -mavx "
        export MAVX512F=-mavx512f
    fi
else
    export CFLAGS="-O3 "
fi
if [[ ${nbits} == 64 ]]; then
    SYMBOL_DEFS=()
    SYMBOLS=(dgemm dtrmm dtrmv dtrsm sgemm strmm strsm ztrmm)
    for sym in ${SYMBOLS[@]}; do
        SYMBOL_DEFS+=("-Dcblas_${sym}=cblas_${sym}64_")
    done
    CFLAGS+=${SYMBOL_DEFS[@]}
    BLAS=openblas64_
else
    BLAS=openblas
fi
make assembly CC=gcc
make lib CC=gcc FT_PREFIX=${prefix} FT_BLAS=${BLAS} FT_FFTW_WITH_COMBINED_THREADS=1
mv -f libfasttransforms.${dlext} ${libdir}
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libfasttransforms", :libfasttransforms),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("FFTW_jll"),
    Dependency("MPFR_jll", v"4.1.1"),
    Dependency("OpenBLAS_jll", v"0.3.17"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", julia_compat="1.7")
