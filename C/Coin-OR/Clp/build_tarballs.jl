include("../coin-or-common.jl")

name = "Clp"
version = Clp_version  # v1.17.9

# Collection of sources required to build Clp
sources = [
    GitSource("https://github.com/coin-or/Clp.git", Clp_gitsha),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Clp*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
update_configure_scripts

# old and custom autoconf
sed -i s/elf64ppc/elf64lppc/ configure

mkdir build
cd build/

export CPPFLAGS="${CPPFLAGS} -DNDEBUG -I${includedir} -I${includedir}/coin"
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L${libdir}"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

if [[ ${target} == *aarch64* ]] || [[ ${target} == *arm* ]]; then
   export CPPFLAGS="${CPPFLAGS} -D__arm__"
fi

# BLAS and LAPACK
if [[ "${target}" == *mingw* ]]; then
  LBT="-lblastrampoline-5"
else
  LBT="-lblastrampoline"
fi

../configure \
    --prefix=$prefix \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-pic \
    --disable-pkg-config \
    --disable-debug \
    --disable-dependency-tracking \
    --enable-shared \
    lt_cv_deplibs_check_method=pass_all \
    --with-blas="-L${libdir} ${LBT}" \
    --with-lapack="-L${libdir} ${LBT}" \
    --with-coinutils-lflags="-lCoinUtils" \
    --with-coinutils-cflags="${includedir}" \
    --with-osi-lflags="-lOsi" \
    --with-osi-cflags="${includedir}" \
    --with-mumps-lflags="-L${libdir} -ldmumps" \
    --with-mumps-cflags="${includedir}/mumps_seq" \
    --with-glpk-lflags="-L${libdir} -lglpk" \
    --with-glpk-cflags="-I${includedir}" \
    --with-amd-lflags="-L${libdir} -lamd" \
    --with-amd-cflags="-I${includedir}" \
    --with-cholmod-lflags="-L${libdir} -lcholmod" \
    --with-cholmod-cflags="-I${includedir}"

make -j${nproc}
make install
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libClp", :libClp),
    LibraryProduct("libOsiClp", :libOsiClp),
    LibraryProduct("libClpSolver", :libClpSolver),
    ExecutableProduct("clp", :clp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CoinUtils_jll", uuid="be027038-0da8-5614-b30d-e42594cb92df"), compat="$(CoinUtils_version)"),
    Dependency(PackageSpec(name="Osi_jll", uuid="7da25872-d9ce-5375-a4d3-7a845f58efdd"), compat="$(Osi_version)"),
    Dependency(PackageSpec(name="SuiteSparse32_jll", uuid="ca45d3f4-326b-53b0-9957-23b75aacb3f2"), compat="$(SuiteSparse32_version)"),
    Dependency(PackageSpec(name="GLPK_jll", uuid="e8aa6df9-e6ca-548a-97ff-1f85fc5b8b98"), compat="$(GLPK_version)"),
    Dependency(PackageSpec(name="MUMPS_seq_jll", uuid="d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d"), compat="$(MUMPS_seq_version_LBT)"),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
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
    preferred_llvm_version = llvm_version,
    julia_compat = "1.9"
)
