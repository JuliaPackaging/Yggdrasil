# In addition to coin-or-common.jl, we need to modify this file to trigger a
# rebuild.
#
# Last updated: 2025-09-23

include("../coin-or-common.jl")

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

# BLAS and LAPACK
if [[ "${target}" == *mingw* ]]; then
  LBT="-lblastrampoline-5"
else
  LBT="-lblastrampoline"
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
    --with-blas \
    --with-blas-lib="-L${libdir} ${LBT}" \
    --with-lapack \
    --with-lapack-lib="-L${libdir} ${LBT}" \
    --with-clp-lib="-lClp" \
    --with-coindepend-lib="-lCgl -lOsiClp -lClp -lOsi -lCoinUtils" \
    --enable-cbc-parallel

make -j${nproc}
make install
"""

# The products that we will ensure are always built
products = [
    LibraryProduct("libCbc", :libCbc),
    LibraryProduct("libOsiCbc", :libOsiCbc),
    LibraryProduct("libCbcSolver", :libcbcsolver),
    ExecutableProduct("cbc", :cbc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("ASL_jll", ASL_version),
    Dependency("Cgl_jll", compat="$(Cgl_version)"),
    Dependency("Clp_jll", compat="$(Clp_version)"),
    Dependency("Osi_jll", compat="$(Osi_version)"),
    Dependency("CoinUtils_jll", compat="$(CoinUtils_version)"),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS,
    "Cbc",
    Cbc_version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = gcc_version,
    preferred_llvm_version = llvm_version,
    julia_compat = "1.9",
)
