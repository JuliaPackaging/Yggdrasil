# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Uno"

version = v"1.1.0"

sources = [
    GitSource(
        "https://github.com/cvanaret/Uno.git",
        "0513043436e4e6dddc7aac71695aea56f5a32285",
    ),
]

script = raw"""
cd $WORKSPACE/srcdir/Uno
mkdir -p build
cd build

if [[ "${target}" == *mingw* ]]; then
    LBT=blastrampoline-5
else
    LBT=blastrampoline
fi

if [[ "${target}" == *apple* ]] || [[ "${target}" == *freebsd* ]]; then
    OMP=omp
else
    OMP=gomp
fi

cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${libdir} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -Damplsolver=${libdir}/libasl.${dlext} \
    -DBLA_VENDOR="libblastrampoline" \
    -DMUMPS_INCLUDE_DIR=${includedir} \
    -DMETIS_INCLUDE_DIR=${includedir} \
    -DMUMPS_LIBRARY="${libdir}/libdmumps.${dlext}" \
    -DMUMPS_COMMON_LIBRARY="${libdir}/libmumps_common.${dlext}" \
    -DMUMPS_PORD_LIBRARY="${libdir}/libpord.${dlext}" \
    -DMUMPS_MPISEQ_LIBRARY="${libdir}/libmpiseq.${dlext}" \
    -DBLAS_LIBRARIES="${libdir}/lib${LBT}.${dlext}" \
    -DLAPACK_LIBRARIES="${libdir}/lib${LBT}.${dlext}" \
    ..

make -j${nproc}
cp libuno.a ${libdir}/libuno.a
cp uno_ampl${exeext} ${bindir}/uno_ampl${exeext}
# ${CXX} -shared $(flagon -Wl,--whole-archive) libuno.a $(flagon -Wl,--no-whole-archive) -o "${libdir}/libuno.${dlext}" -L${OMP} -l${LBT} -ldmumps -lmetis
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("uno_ampl", :amplexe),
    FileProduct("lib/libuno.a", :libuno),
]

dependencies = [
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70")),
    Dependency(PackageSpec(name="ASL_jll", uuid="ae81ac8f-d209-56e5-92de-9978fef736f9"), compat="0.1.3"),
    Dependency(PackageSpec(name="MUMPS_seq_jll", uuid="d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD systems),
    # and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),

    # We need at least 3.29 (Ygg version), or 3.30 upstream version for LBT support,
    # so always pull the most recent CMake version.
    HostBuildDependency(PackageSpec(name="CMake_jll", uuid="3f4e10e2-61f2-5801-8945-23b9d642d0e6")),
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.9",
    preferred_gcc_version = v"10.2.0",
)
