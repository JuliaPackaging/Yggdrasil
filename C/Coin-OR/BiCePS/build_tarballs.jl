include("../coin-or-common.jl")

sources = [
    GitSource("https://github.com/coin-or/CHiPPS-BiCePS.git", BiCePS_gitsha),
]

script = raw"""
export CPPFLAGS="${CPPFLAGS} -I${includedir} -I${includedir}/coin"
if [[ "${target}" == *mingw* ]]; then
    export LDFLAGS="-L${bindir}"
elif [[ "${target}" == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

cd $WORKSPACE/srcdir/CHiPPS-BiCePS
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
    --with-coinutils-lib="-lCoinUtils" \
    --with-osi-lib="-lOsi" \
    --with-clp-lib="-lClp -lOsiClp" \
    --with-cgl-lib="-lCgl" \
    --with-alps-lib="-lAlps -lCoinUtils" \
    --with-coindepend-lib="-lCgl -lClp -lOsi -lCoinUtils"
make -j${nproc}
make install
"""

products = [
    LibraryProduct("libBcps", :libbcps),
]

dependencies = [
    Dependency("CoinUtils_jll", compat="$(CoinUtils_version)"),
    Dependency("Osi_jll", compat="$(Osi_version)"),
    Dependency("Clp_jll", compat="$(Clp_version)"),
    Dependency("Cgl_jll", compat="$(Cgl_version)"),
    Dependency("ALPS_jll", compat="$(ALPS_version)"),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(
    ARGS,
    "BiCePS",
    BiCePS_version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = gcc_version,
    julia_compat = "1.6",
)
