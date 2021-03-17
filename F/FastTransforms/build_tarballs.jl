using BinaryBuilder

# Collection of sources required to build FastTransforms
name = "FastTransforms"
version = v"0.5.1"
sources = [
    ArchiveSource("https://github.com/MikaelSlevinsky/FastTransforms/archive/v$(version).tar.gz",
                  "bee3c4f0d33487f0b0ad44fcaea24bd064a83e415faa46b4d237c40631dd1523"),
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
if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
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
    Dependency("MPFR_jll", v"4.0.2"),
    Dependency("OpenBLAS_jll", v"0.3.9"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"5")
