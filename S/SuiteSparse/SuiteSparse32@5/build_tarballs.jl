include("../common.jl")

name = "SuiteSparse32"
version = v"5.10.1"

sources = suitesparse_sources(version)

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SuiteSparse

# Disable OpenMP as it will probably interfere with blas threads and Julia threads
FLAGS+=(INSTALL="${prefix}" INSTALL_LIB="${libdir}" INSTALL_INCLUDE="${prefix}/include" CFOPENMP=)

FLAGS+=(LDFLAGS="${LDFLAGS} -L${libdir}")
if [[ ${target} == *mingw32* ]]; then
    FLAGS+=(UNAME=Windows)
else
    FLAGS+=(UNAME="$(uname)")
fi

mkdir -p ${prefix}/include
make -j${nproc} -C SuiteSparse_config "${FLAGS[@]}" config
cp SuiteSparse_config/SuiteSparse_config.h ${prefix}/include
for proj in SuiteSparse_config AMD BTF COLAMD KLU; do
    make -j${nproc} -C $proj "${FLAGS[@]}" static CFOPENMP="$CFOPENMP"
    [[ -d ${proj}/Include ]] && cp ${proj}/Include/*.h ${prefix}/include
done

# Move the static libraries into place
mkdir -p $libdir
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
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
