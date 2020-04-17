include("../coin-or-common.jl")

name = "Osi"
version = Osi_version

# Collection of sources required to build OsiBuilder
sources = [
    GitSource("https://github.com/coin-or/Osi.git",
              Osi_gitsha)
]

script = raw"""
cd $WORKSPACE/srcdir/Osi*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
rm -f /opt/${target}/${target}/lib*/*.la
update_configure_scripts

mkdir build
cd build/

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include -I${prefix}/include/coin"
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L$prefix/bin"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

../configure --prefix=$prefix --with-pic --disable-pkg-config --build=${MACHTYPE} --host=${target} \
--enable-shared lt_cv_deplibs_check_method=pass_all \
--with-coinutils-lib="-lCoinUtils" \
--with-blas-lib="-lopenblas" --with-lapack-lib="-lopenblas"

make -j${nproc}
make install
"""

# The products that we will ensure are always built
products = [
    LibraryProduct("libOsi", :libOsi),
    LibraryProduct("libOsiCommonTests", :libOsiCommonTests),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(CoinUtils_packagespec),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=gcc_version)
