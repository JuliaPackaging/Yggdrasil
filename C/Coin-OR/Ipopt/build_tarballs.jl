include("../coin-or-common.jl")

name = "Ipopt"
version = Ipopt_version  # v3.14.17

sources = [
    GitSource("https://github.com/coin-or/Ipopt.git", Ipopt_gitsha)
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Ipopt*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la

LIBASL="-lasl"
if [[ "${target}" == *-linux-* ]]; then
  LIBASL="${LIBASL} -lrt"
fi

export CPPFLAGS="${CPPFLAGS} -I${includedir} -I${includedir}/coin"

if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L${libdir}"
fi

# BLAS and LAPACK
if [[ "${target}" == *mingw* ]]; then
  LBT="-lblastrampoline-5"
else
  LBT="-lblastrampoline"
fi

./configure \
    CFLAGS="-O3 -DNDEBUG" \
    CXXFLAGS="-O3 -DNDEBUG" \
    FFLAGS="-O3" \
    FCFLAGS="-O3" \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared \
    --with-pic \
    --disable-dependency-tracking \
    lt_cv_deplibs_check_method=pass_all \
    --with-lapack-lflags="-L${libdir} ${LBT}" \
    --with-mumps-cflags="-I${includedir}/libseq" \
    --with-mumps-lflags="-L${libdir} -ldmumps" \
    --with-spral-cflags="-I${includedir}" \
    --with-spral-lflags="-L${libdir} -lspral" \
    --with-asl-lflags="-L${libdir} ${LIBASL}"

make -j${nproc}
make install
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# Disable aarch64-freebsd until we recompile the dependencies.
platforms = filter(p -> !(os(p) == "freebsd" && arch(p) == "aarch64"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libipopt", :libipopt),
    LibraryProduct("libipoptamplinterface", :libipoptamplinterface),
    ExecutableProduct("ipopt", :amplexe),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="ASL_jll", uuid="ae81ac8f-d209-56e5-92de-9978fef736f9"), ASL_version),
    Dependency(PackageSpec(name="MUMPS_seq_jll", uuid="d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d"), compat="=$(MUMPS_seq_version_LBT)"),
    Dependency(PackageSpec(name="SPRAL_jll", uuid="319450e9-13b8-58e8-aa9f-8fd1420848ab"), compat="=$(SPRAL_version_LBT)"),
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
