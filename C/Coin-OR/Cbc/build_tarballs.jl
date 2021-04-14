include("../coin-or-common.jl")

name = "Cbc"
version = Cbc_version

# Collection of sources required to build CbcBuilder
sources = [
    GitSource("https://github.com/coin-or/Cbc.git", Cbc_gitsha),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Cbc*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
update_configure_scripts

# old and custom autoconf
sed -i s/elf64ppc/elf64lppc/ configure

mkdir build
cd build/

export CPPFLAGS="${CPPFLAGS} -DNDEBUG -I${includedir} -I${includedir}/coin"
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L$prefix/bin"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

../configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-pic \
    --disable-pkg-config \
    --disable-debug \
    --enable-shared \
    lt_cv_deplibs_check_method=pass_all \
    --with-asl-lib="-lasl" \
    --with-blas-lib="-lopenblas" \
    --with-lapack-lib="-lopenblas" \
    --with-metis-lib="-lmetis" \
    --with-coinutils-lib="-lCoinUtils" \
    --with-osi-lib="-lOsi" \
    --with-clp-lib="-lClp" \
    --with-cgl-lib="-lCgl -lOsiClp " \
    --with-coindepend-lib="-lCgl -lOsiClp -lClp -lOsi -lCoinUtils" \
    --enable-cbc-parallel

make -j${nproc}
make install
"""

# The products that we will ensure are always built
products = [
    LibraryProduct("libCbc", :libCbc),
    LibraryProduct("libCbcSolver", :libcbcsolver),
    ExecutableProduct("cbc", :cbc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("ASL_jll", ASL_version),
    Dependency("Cgl_jll", Cgl_version),
    Dependency("Clp_jll", Clp_version),
    Dependency("Osi_jll", Osi_version),
    Dependency("CoinUtils_jll", CoinUtils_version),
    Dependency("OpenBLAS32_jll", OpenBLAS32_version),
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, expand_gfortran_versions(platforms), products, dependencies;
               preferred_gcc_version=gcc_version)
