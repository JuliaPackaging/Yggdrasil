using BinaryBuilder

# Collection of sources required to build FastTransforms
name = "FastTransforms"
version = v"0.2.10"
sources = [
    "https://github.com/MikaelSlevinsky/FastTransforms/archive/v$(version).tar.gz" =>
    "33ee9dc2181d060080d97aaf90b75ed8488a2a5bbc1552ac263d1b6c852647b4",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/FastTransforms-*
if [[ ${nbits} == 64 ]]; then
    BLAS=openblas64_
else
    BLAS=openblas
fi
make lib CC=gcc FT_PREFIX=${prefix} FT_BLAS=${BLAS} FT_FFTW_WITH_COMBINED_THREADS=1
mv -f libfasttransforms.${dlext} ${libdir}
"""

platforms = expand_gfortran_versions([Linux(:i686, libc=:glibc);
                                      Linux(:x86_64, libc=:glibc);
                                      Linux(:i686, libc=:musl);
                                      Linux(:x86_64, libc=:musl);
                                      MacOS(:x86_64);
                                      FreeBSD(:x86_64);
                                      Windows(:i686);
                                      Windows(:x86_64)])

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
