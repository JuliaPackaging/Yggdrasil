include("../coin-or-common.jl")

name = "CoinUtils"
version = CoinUtils_version

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/coin-or/CoinUtils.git",
              CoinUtils_gitsha),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CoinUtils*

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
--with-blas --with-blas-lib="-lopenblas" \
--with-lapack --with-lapack-lib="-lopenblas"

make -j${nproc}
make install
"""

# The products that we will ensure are always built
products = [
    LibraryProduct("libCoinUtils", :libCoinUtils)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=gcc_version)
