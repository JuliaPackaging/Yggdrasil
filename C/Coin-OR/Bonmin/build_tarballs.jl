include("../coin-or-common.jl")

name = "Bonmin"
version = Bonmin_version

sources = [
    GitSource("https://github.com/coin-or/Bonmin.git", Bonmin_gitsha),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Bonmin

if [[ ${target} == *mingw* ]]; then
    sed -i s/dllimport/dllexport/ "${includedir}/coin-or/IpoptConfig.h"
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fix_dllexport.patch
fi

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
fi

./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-pkg-config \
    --disable-debug \
    --enable-shared \
    lt_cv_deplibs_check_method=pass_all \
    --with-asl-lib="-lasl" \
    --with-coindepend-lib="-lCbc -lCgl -lOsiClp -lClp -lOsi -lCoinUtils -lipoptamplinterface -lipopt"

make -j${nproc}
make install

# Prevent IpoptConfig.h from being included in the tarball after editing it above.
rm "${includedir}/coin-or/IpoptConfig.h"
"""

filter!(x -> cxxstring_abi(x) != "cxx03", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libbonmin", :libbonmin),
    LibraryProduct("libbonminampl", :libbonminampl),
    ExecutableProduct("bonmin", :amplexe),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("ASL_jll", ASL_version),
    Dependency("Cbc_jll", Cbc_version, compat="=$(Cbc_version)"),
    Dependency("Cgl_jll", Cgl_version),
    Dependency("Clp_jll", Clp_version),
    Dependency("Osi_jll", Osi_version),
    Dependency("CoinUtils_jll", CoinUtils_version),
    Dependency("Ipopt_jll", Ipopt_version, compat="=$(Ipopt_version)"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
