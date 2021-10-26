using BinaryBuilder, Pkg

name = "Couenne"
version = v"0.5.8"

sources = [
    GitSource("https://github.com/coin-or/Couenne.git",
              "7154f7a9b3cd84be378d02b483d090b76fc79ce8"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Couenne

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fixes.patch

if [[ ${target} == *mingw* ]]; then
    # Disable user-interrupts on Windows.
    sed -i s/'#define SIGNAL'// ${WORKSPACE}/srcdir/Couenne/Couenne/src/main/CouenneBab.cpp
    # Export symbols from DLL
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/export.patch
fi

# asl.h defines a macro called `filename`. Very unhelpful.
sed -i s/'#define filename'/'#define __asl_filename'/ /workspace/destdir/include/asl.h
sed -i s/'filename;'/'__asl_filename;'/ /workspace/srcdir/Couenne/Couenne/src/readnl/readnl.cpp

# Remove misleading libtool files
rm -f ${libdir}/*.la
update_configure_scripts

# old and custom autoconf
sed -i s/elf64ppc/elf64lppc/ configure

export CPPFLAGS="${CPPFLAGS} -I${includedir} -I${includedir}/coin -I${includedir}/coin-or"
export CXXFLAGS="${CXXFLAGS} -std=c++11"

if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L${libdir}"
    export LT_LDFLAGS="-no-undefined"
elif [[ ${target} == *apple* ]]; then
    # Turn off the annoying, but harmless, -Wdeprecated-register.
    export CPPFLAGS="${CPPFLAGS} -Wno-deprecated-register"
fi

./configure \
    --prefix=$prefix \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-static \
    --enable-shared \
    lt_cv_deplibs_check_method=pass_all \
    --with-asl-lib="-lasl -lipoptamplinterface" \
    --with-bonmin-lib="-lbonminampl -lbonmin -lipoptamplinterface -lipopt -lCbc -lCgl -lOsiClp -lClp -lOsi -lCoinUtils -lasl -lopenblas"

make -j${nproc}
make install
"""

platforms = supported_platforms()
platforms = filter!(!Sys.isfreebsd, platforms)
platforms = expand_cxxstring_abis(platforms)
platforms = filter(x -> cxxstring_abi(x) != "cxx03", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libCouenne", :libcouenne),
    ExecutableProduct("couenne", :amplexe),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("ASL_jll", v"0.1.2"),
    Dependency("Bonmin_jll", v"1.8.8"),
    Dependency("Cbc_jll", v"2.10.5"),
    Dependency("Ipopt_jll", v"3.13.4"),
]

# Note: for obscure reasons I miss, `Clp_jll` built for
# `x86_64-linux-gnu-libgfortran3-cxx11` with GCC 6.1 provides the symbol
#     virtual thunk to OsiClpSolverInterface::getRowName(int, unsigned int) const
# instead of
#     virtual thunk to OsiClpSolverInterface::getRowName[abi:cxx11](int, unsigned int) const
# Thus, if we build Couenne with GCC < 7 (=> libgfortran3) we'd have the symbol
# without the `abi:cxx11` tag.  Auditor doesn't complain because at the end of
# the build everything has a consistent ABI for the libgfortran3 runtime.
# However, when we load the package at runtime we'd have libgfortran5 and the
# corresponding Clp provides the `abi:cxx11`-tagged symbol, causing the error
#    /tmp/jl_KKxJ1h/artifacts/ecc837f417130ef88b6288424541354733c387b1/lib/libCouenne.so: undefined symbol: _ZTv0_n720_NK21OsiClpSolverInterface10getRowNameEij
# The solution is to build Couenne with GCC 7 (=> libgfortran4) so that
# `Clp_jll` used during the build has the correctly tagged symbol.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
