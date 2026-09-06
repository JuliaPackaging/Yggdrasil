include("../coin-or-common.jl")

sources = [
    GitSource("https://github.com/coin-or/Couenne.git", Couenne_gitsha),
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

# BLAS and LAPACK
if [[ "${target}" == *mingw* ]]; then
  LBT="-lblastrampoline-5"
else
  LBT="-lblastrampoline"
fi

./configure \
    --prefix=$prefix \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-static \
    --enable-shared \
    lt_cv_deplibs_check_method=pass_all \
    --with-asl-lib="-lasl -lipoptamplinterface" \
    --with-bonmin-lib="-lbonminampl -lbonmin -lipoptamplinterface -lipopt -lCbc -lCgl -lOsiClp -lClp -lOsi -lCoinUtils -lasl ${LBT}"

make -j${nproc}
make install
"""

platforms = filter(x -> cxxstring_abi(x) != "cxx03", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libCouenne", :libcouenne),
    ExecutableProduct("couenne", :amplexe),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("ASL_jll"),
    Dependency("Bonmin_jll", compat="$(Bonmin_version)"),
    Dependency("Cbc_jll", compat="$(Cbc_version)"),
    Dependency("Ipopt_jll", compat="$(Ipopt_version)"),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
]

build_tarballs(
    ARGS,
    "Couenne",
    Couenne_version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = gcc_version,
    preferred_llvm_version = llvm_version,
    julia_compat = "1.9",
)
