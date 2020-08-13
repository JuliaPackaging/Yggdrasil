using BinaryBuilder

name = "SuiteSparse32"
version = v"5.4.0"

# Collection of sources required to build SuiteSparse
sources = [
    ArchiveSource("https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/v$(version).tar.gz",
                  "d9d62d539410d66550d0b795503a556830831f50087723cb191a030525eda770"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SuiteSparse-*

# Disable OpenMP as it will probably interfere with blas threads and Julia threads
FLAGS+=(INSTALL="${prefix}" INSTALL_LIB="${libdir}" INSTALL_INCLUDE="${prefix}/include" CFOPENMP=)

FLAGS+=(LDFLAGS="${LDFLAGS} -L${libdir}")
if [[ ${target} == *mingw32* ]]; then
    FLAGS+=(UNAME=Windows)
else
    FLAGS+=(UNAME="$(uname)")
fi

FLAGS+=(BLAS="-lopenblas" LAPACK="-lopenblas")

# Disable METIS in CHOLMOD by passing -DNPARTITION and avoiding linking metis
#FLAGS+=(MY_METIS_LIB="-lmetis" MY_METIS_INC="${prefix}/include")
FLAGS+=(UMFPACK_CONFIG="$SUN" CHOLMOD_CONFIG+="$SUN -DNPARTITION" SPQR_CONFIG="$SUN")

make -j${nproc} -C SuiteSparse_config "${FLAGS[@]}" config

for proj in SuiteSparse_config AMD BTF COLAMD KLU; do
    make -j${nproc} -C $proj "${FLAGS[@]}" static CFOPENMP="$CFOPENMP"
done

# Move the static libraries into place
pat="*.a"
if [[ ${target} == *mingw32* ]]; then
    pat="*.lib"
fi
find . -name "$pat" -exec mv {} ${libdir} \;

install_license LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    FileProduct(["lib/libsuitesparseconfig.a", "bin/libsuitesparseconfig.lib"],  :libsuitesparseconfig_a),
    FileProduct(["lib/libamd.a", "bin/libamd.lib"],                              :libamd_a),
    FileProduct(["lib/libbtf.a", "bin/libbtf.lib"],                              :libbtf_a),
    FileProduct(["lib/libcolamd.a", "bin/libcolamd.lib"],                        :libcolamd_a),
    FileProduct(["lib/libklu.a", "bin/libklu.lib"],                              :libklu_a),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll"),
#    Dependency("METIS_jll"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
