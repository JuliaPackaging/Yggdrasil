include("../coin-or-common.jl")

name = "Cbc"
version = Cbc_version

# Collection of sources required to build CbcBuilder
sources = [
    GitSource("https://github.com/coin-or/Cbc.git",
              Cbc_gitsha),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Cbc*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
rm -f /opt/${target}/${target}/lib*/*.la
update_configure_scripts

# Apply patch related to https://github.com/JuliaOpt/Cbc.jl/issues/117 and https://github.com/coin-or/Cbc/issues/267
(cd Cbc/src && atomic_patch -p0 $WORKSPACE/srcdir/patches/no_lp.patch)

mkdir build
cd build/

export CPPFLAGS="${CPPFLAGS} -DNDEBUG -I${prefix}/include -I$prefix/include/coin"
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L$prefix/bin"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

../configure --prefix=$prefix --with-pic --disable-pkg-config  --build=${MACHTYPE} --host=${target} \
--enable-shared lt_cv_deplibs_check_method=pass_all \
--with-blas-lib="-lopenblas" --with-lapack-lib="-lopenblas" \
--with-metis-lib="-lmetis" \
--with-coinutils-lib="-lCoinUtils" \
--with-osi-lib="-lOsi -lCoinUtils" \
--with-clp-lib="-lClp -lOsiClp -lCoinUtils" \
--with-cgl-lib="-lCgl -lClp -lOsiClp -lOsi -lCoinUtils" \
--with-coindepend-lib="-lCgl -lClp -lOsiClp -lOsi -lCoinUtils" \
--enable-cbc-parallel

make -j${nproc}
make install
"""

# The products that we will ensure are always built
products = [
    LibraryProduct("libCbc", :libCbc),
    LibraryProduct("libCbcSolver", :libcbcsolver),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(Clp_packagespec),
    Dependency(Cgl_packagespec),
    Dependency(Osi_packagespec),
    Dependency(CoinUtils_packagespec),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, expand_gfortran_versions(platforms), products, dependencies;
               preferred_gcc_version=gcc_version)
