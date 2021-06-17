include("../coin-or-common.jl")

sources = [
    GitSource("https://github.com/coin-or/CHiPPS-BLIS.git", CHiPPS_BLIS_gitsha),
]

script = raw"""
export CPPFLAGS="${CPPFLAGS} -I${includedir} -I${includedir}/coin"
if [[ "${target}" == *mingw* ]]; then
    export LDFLAGS="-L${bindir}"
elif [[ "${target}" == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi
cd $WORKSPACE/srcdir/CHiPPS-BLIS
rm -f ${prefix}/lib/*.la
update_configure_scripts
sed -i s/elf64ppc/elf64lppc/ configure
mkdir build
cd build
../configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-pic \
    --disable-pkg-config \
    --disable-debug \
    --disable-dependency-tracking \
    --enable-shared \
    lt_cv_deplibs_check_method=pass_all \
    --with-coindepend-lib="-lBcps -lAlps -lCgl -lOsiClp -lClp -lOsi -lCoinUtils"
make -j${nproc}
make install
"""

products = [
    ExecutableProduct("blis", :blis),
    LibraryProduct("libBlis", :libblis),
]

dependencies = [
    Dependency("CoinUtils_jll", CoinUtils_version),
    Dependency("Osi_jll", Osi_version),
    Dependency("Clp_jll", Clp_version),
    Dependency("Cgl_jll", Cgl_version),
    Dependency("ALPS_jll", ALPS_version),
    Dependency("BiCePS_jll", BiCePS_version),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(
    ARGS,
    "CHiPPS_BLIS",
    CHiPPS_BLIS_version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = gcc_version,
    julia_compat = "1.6",
)
