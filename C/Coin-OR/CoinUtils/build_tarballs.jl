using BinaryBuilder

name = "CoinUtils"
version = v"2.11.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/coin-or/CoinUtils.git", "ea66474879246f299e977802c94a0e45334e7afb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CoinUtils*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
rm -f /opt/${target}/${target}/lib*/*.la
update_configure_scripts

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
export CXXFLAGS="${CXXFLAGS} -std=c++11"
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L$prefix/bin"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared --with-pic --disable-pkg-config \
lt_cv_deplibs_check_method=pass_all \
--with-blas --with-blas-lib="-lopenblas" \
--with-lapack --with-lapack-lib="-lopenblas"

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
