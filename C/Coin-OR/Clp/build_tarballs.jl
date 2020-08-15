include("../coin-or-common.jl")

name = "Clp"
version = Clp_version

# Collection of sources required to build Clp
sources = [
    GitSource("https://github.com/coin-or/Clp.git",
              Clp_gitsha)
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Clp*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
rm -f /opt/${target}/${target}/lib*/*.la
update_configure_scripts

# old and custom autoconf
sed -i s/elf64ppc/elf64lppc/ configure

mkdir build
cd build/

export CPPFLAGS="${CPPFLAGS} -DNDEBUG -I${prefix}/include -I$prefix/include/coin"
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L$prefix/bin"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

if [[ ${target} == *aarch64* ]] || [[ ${target} == *arm* ]]; then
   export CPPFLAGS="${CPPFLAGS} -D__arm__"
fi

../configure --prefix=$prefix --with-pic --disable-pkg-config --build=${MACHTYPE} --host=${target} \
--disable-debug --disable-dependency-tracking \
--enable-shared lt_cv_deplibs_check_method=pass_all \
--with-blas="-lopenblas" --with-lapack="-lopenblas" \
--with-coinutils-lib="-lCoinUtils" \
--with-osi-lib="-lOsi -lCoinUtils" \
--with-mumps-lib="-L${prefix}/lib -ldmumps -lzmumps -lcmumps -lsmumps -lmumps_common -lmpiseq -lpord -lmetis -lopenblas -lgfortran -lpthread" \
--with-mumps-incdir="${prefix}/include/mumps_seq" \
--with-metis-lib="-L${prefix}/lib -lmetis" --with-metis-incdir="${prefix}/include"

make -j${nproc}
make install
"""

# The products that we will ensure are always built
products = [
    LibraryProduct("libClp", :libClp),
    LibraryProduct("libOsiClp", :libOsiClp),
    LibraryProduct("libClpSolver", :libClpSolver)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(CoinUtils_packagespec),
    Dependency(Osi_packagespec),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    BuildDependency(MUMPS_seq_packagespec),
    BuildDependency(METIS_packagespec),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, expand_gfortran_versions(platforms), products, dependencies;
               preferred_gcc_version=gcc_version)
