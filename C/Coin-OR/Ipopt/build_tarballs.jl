include("../coin-or-common.jl")

name = "Ipopt"
version = Ipopt_version

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

if [[ "${target}" == *mingw* ]]; then
  BLAS_LAPACK="-L${libdir} -lopenblas"
else
  BLAS_LAPACK="-L${libdir} -lblastrampoline"
fi

./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared \
    --enable-static \
    --with-pic \
    --disable-dependency-tracking \
    lt_cv_deplibs_check_method=pass_all \
    --with-lapack-lflags="${BLAS_LAPACK}" \
    --with-mumps-cflags="-I${includedir}" \
    --with-mumps-lflags="-ldmumps -lzmumps -lcmumps -lsmumps -lmumps_common -lmpiseq -lpord -lmetis ${BLAS_LAPACK} -lgfortran -lpthread" \
    --with-asl-lflags="${LIBASL}"

# parallel build fails
make
make install
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

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
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"), platforms=filter(Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), platforms=filter(!Sys.iswindows, platforms)),
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
    julia_compat = "1.8"
)
