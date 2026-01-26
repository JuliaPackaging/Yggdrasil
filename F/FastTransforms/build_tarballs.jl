using BinaryBuilder, Pkg

# Collection of sources required to build FastTransforms
name = "FastTransforms"
version = v"0.6.3"
sources = [
    GitSource("https://github.com/MikaelSlevinsky/FastTransforms.git", "abd33bc1e99f9e75cff7ade1154ecc2f4cec6a62")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/FastTransforms/
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
    SYMBOLS=(dgemv dgemm dtrmm dtrmv dtrsm sgemv sgemm strmm strsm ztrmm)
    for sym in ${SYMBOLS[@]}; do
        SYMBOL_DEFS+=("-Dcblas_${sym}=cblas_${sym}64_")
    done
    CFLAGS+=${SYMBOL_DEFS[@]}
    BLAS=openblas64_
else
    BLAS=openblas
fi
make assembly
make lib FT_PREFIX=${prefix} FT_BLAS=${BLAS} FT_FFTW_WITH_COMBINED_THREADS=1
mv -f libfasttransforms.${dlext} ${libdir}
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libfasttransforms", :libfasttransforms),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("FFTW_jll"),
    Dependency("MPFR_jll", v"4.1.1"),
    Dependency("OpenBLAS_jll", v"0.3.17"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", julia_compat="1.7")
