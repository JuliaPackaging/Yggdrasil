using BinaryBuilder

# Collection of sources required to build FastTransforms
name = "FastTransforms"
version = v"0.2.9"
sources = [
    "https://github.com/MikaelSlevinsky/FastTransforms/archive/v$(version).tar.gz" =>
    "555e8fb19ad76ee888fbab7bfaf4c269416c1c5950e9428cbe08edb44c22bf35",
]

# Bash recipe for building across all platforms
script = raw"""
if [[ ${target} != *darwin* ]]; then
    if [[ ${target} == *mingw* ]]; then
        cd $WORKSPACE/destdir/bin
    else
        cd $WORKSPACE/destdir/lib
    fi
    if [[ ${nbits} == 32 ]]; then
        ln -sf libopenblas.${dlext} libblas.${dlext}
    else
        ln -sf libopenblas64_.${dlext} libblas.${dlext}
    fi
fi

cd $WORKSPACE/srcdir/FastTransforms-*

if [[ ${target} == *mingw* ]]; then
    gcc  -std=gnu99 -Ofast -march=native -mtune=native -mno-vzeroupper -I./src -I/workspace/destdir/include -lm -shared -fPIC src/transforms.c src/rotations.c src/permute.c src/tdc.c src/drivers.c src/fftw.c -L/workspace/destdir/bin -lm -lquadmath -fopenmp -lblas -lfftw3 -lgmp -lmpfr -o libfasttransforms.dll
    cp -a libfasttransforms.${dlext} ${prefix}/bin
else
    make lib CC=gcc FT_USE_PREDEFINED_LIBRARIES=1 FT_FFTW_WITH_COMBINED_THREADS=1
    cp -a libfasttransforms.${dlext} ${prefix}/lib
fi
"""

platforms = expand_gfortran_versions([Linux(:i686, libc=:glibc);
                                      Linux(:x86_64, libc=:glibc);
                                      Linux(:i686, libc=:musl);
                                      Linux(:x86_64, libc=:musl);
                                      #MacOS(:x86_64);
                                      FreeBSD(:x86_64);
                                      Windows(:i686)])#;
                                      #Windows(:x86_64)])

# The products that we will ensure are always built
products = [
    LibraryProduct("libfasttransforms", :libfasttransforms),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "CompilerSupportLibraries_jll";
    "FFTW_jll";
    "GMP_jll";
    "MPFR_jll";
    "OpenBLAS_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
