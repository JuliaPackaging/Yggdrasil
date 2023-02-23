# In addition to coin-or-common.jl, we need to modify this file to trigger a
# rebuild.
#
# Last updated: 2022-10-26

include("../coin-or-common.jl")

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
    --with-blas="-lopenblas" \
    --with-lapack="-lopenblas" \
    --with-coinutils-lib="-lCoinUtils" \
    --with-osi-lib="-lOsi -lCoinUtils" \
    --with-mumps-lib="-L${libdir} -ldmumps -lzmumps -lcmumps -lsmumps -lmumps_common -lmpiseq -lpord -lmetis -lopenblas -lgfortran -lpthread" \
    --with-mumps-incdir="${includedir}/mumps_seq" \
    --with-metis-lib="-L${libdir} -lmetis" \
    --with-metis-incdir="${includedir}"

make -j${nproc}
make install
"""

# The products that we will ensure are always built
products = [
    LibraryProduct("libClp", :libClp),
    LibraryProduct("libOsiClp", :libOsiClp),
    LibraryProduct("libClpSolver", :libClpSolver),
    ExecutableProduct("clp", :clp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CoinUtils_jll", compat="$(CoinUtils_version)"),
    Dependency("Osi_jll", compat="$(Osi_version)"),
    Dependency("METIS_jll", compat="$(METIS_version)"),
    Dependency("MUMPS_seq_jll", compat="$(MUMPS_seq_version)"),
    Dependency("OpenBLAS32_jll", OpenBLAS32_version),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS,
    "Clp",
    Clp_version,
    sources,
    script,
    expand_gfortran_versions(platforms),
    products,
    dependencies;
    preferred_gcc_version = gcc_version,
    julia_compat = Julia_compat_version,
)
