include("../coin-or-common.jl")

# Collection of sources required to build SYMPHONY
sources = [
    GitSource("https://github.com/coin-or/SYMPHONY.git", SYMPHONY_gitsha),
]

# Bash recipe for building across all platforms
script = raw"""
export CPPFLAGS="${CPPFLAGS} -I${includedir} -I${includedir}/coin"
if [[ "${target}" == *mingw* ]]; then
    export LDFLAGS="-L${bindir}"
elif [[ "${target}" == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

cd $WORKSPACE/srcdir/SYMPHONY
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
    --with-coindepend-lib="-lOsi -lCoinUtils" \
    --with-clp-lib="-lClp -lOsiClp" \
    --with-cgl-lib="-lCgl"
make -j${nproc}
make install
"""

# The products that we will ensure are always built
products = [
    LibraryProduct("libSym", :libsym),
    LibraryProduct("libOsiSym", :libosisym),
    ExecutableProduct("symphony", :symphony),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CoinUtils_jll", CoinUtils_version),
    Dependency("Osi_jll", Osi_version),
    Dependency("Clp_jll", Clp_version),
    Dependency("Cgl_jll", Cgl_version),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS,
    "SYMPHONY",
    SYMPHONY_version,
    sources,
    script,
    expand_gfortran_versions(platforms),
    products,
    dependencies;
    preferred_gcc_version=gcc_version,
)


