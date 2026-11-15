# In addition to coin-or-common.jl, we need to modify this file to trigger a
# rebuild.
#
# Last updated: 2025-10-07

include("../coin-or-common.jl")

sources = [
    GitSource("https://github.com/coin-or/MibS.git", MibS_gitsha),
]

script = raw"""
export CPPFLAGS="${CPPFLAGS} -I${includedir} -I${includedir}/coin"
if [[ "${target}" == *mingw* ]]; then
    export LDFLAGS="-L${bindir}"
elif [[ "${target}" == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi
cd $WORKSPACE/srcdir/MibS
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
    --with-cbc-lib="-lOsiCbc -lCbc" \
    --with-symphony-lib="-lOsiSym -lSym" \
    --with-coindepend-lib="-lBlis -lBcps -lAlps -lCgl -lOsiClp -lClp -lOsi -lCoinUtils"
make -j${nproc}
make install
"""

products = [
    ExecutableProduct("mibs", :mibs),
    LibraryProduct("libMibs", :libmibs),
]

dependencies = [
    Dependency("CoinUtils_jll", compat="$(CoinUtils_version)"),
    Dependency("Osi_jll", compat="$(Osi_version)"),
    Dependency("Clp_jll", compat="$(Clp_version)"),
    Dependency("Cgl_jll", compat="$(Cgl_version)"),
    Dependency("Cbc_jll", compat="$(Cbc_version)"),
    Dependency("SYMPHONY_jll", compat="$(SYMPHONY_version)"),
    Dependency("ALPS_jll", compat="$(ALPS_version)"),
    Dependency("BiCePS_jll", compat="$(BiCePS_version)"),
    Dependency("CHiPPS_BLIS_jll", compat="$(CHiPPS_BLIS_version)"),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(
    ARGS,
    "MibS",
    MibS_version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = gcc_version,
    preferred_llvm_version = llvm_version,
    julia_compat = "1.9",
)
