# In addition to coin-or-common.jl, we need to modify this file to trigger a
# rebuild.
#
# Last updated: 2022-10-26

include("../coin-or-common.jl")

name = "Osi"
version = Osi_version

# Collection of sources required to build OsiBuilder
sources = [
    GitSource("https://github.com/coin-or/Osi.git", Osi_gitsha),
]

script = raw"""
cd $WORKSPACE/srcdir/Osi*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
update_configure_scripts

# old and custom autoconf
sed -i s/elf64ppc/elf64lppc/ configure

mkdir build
cd build/

export CPPFLAGS="${CPPFLAGS} -I${includedir} -I${includedir}/coin"
if [[ "${target}" == *mingw* ]]; then
    export LDFLAGS="-L${bindir}"
elif [[ "${target}" == *linux* ]]; then
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
    --with-coinutils-lib="-lCoinUtils" \
    --with-blas-lib="-lopenblas" \
    --with-lapack-lib="-lopenblas"

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
    Dependency("CoinUtils_jll", compat="$(CoinUtils_version)"),
    Dependency("OpenBLAS32_jll", OpenBLAS32_version),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = gcc_version,
    julia_compat = "1.6",
)
