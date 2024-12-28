# In addition to coin-or-common.jl, we need to modify this file to trigger a
# rebuild.
#
# Last updated: 2024-07-15

include("../coin-or-common.jl")

name = "CoinUtils"
version = CoinUtils_version

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://github.com/coin-or/CoinUtils/archive/refs/tags/releases/$(CoinUtils_upstream_version).tar.gz",
        CoinUtils_hash,
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CoinUtils*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
update_configure_scripts

# Without fixing this configure reports that we can't build shared
# libraries. We use `elf64lppc` for LE support. This seems to be
# fixed on master, but using `update_configure_scripts -reconf` breaks.
sed -i s/elf64ppc/elf64lppc/ configure

mkdir build
cd build/

export CPPFLAGS="${CPPFLAGS} -I${includedir} -I${includedir}/coin"
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L${libdir}"
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
    --with-blas \
    --with-blas-lib="-L${libdir} ${LBT}" \
    --with-lapack \
    --with-lapack-lib="-L${libdir} ${LBT}"

make -j${nproc}
make install
"""

# The products that we will ensure are always built
products = [
    LibraryProduct("libCoinUtils", :libCoinUtils)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
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
    julia_compat = "1.9",
)
