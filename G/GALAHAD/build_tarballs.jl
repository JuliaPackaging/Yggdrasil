# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GALAHAD"
version = v"5.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ralna/GALAHAD.git", "17cecabc1aae869dc80b071d7c6c93e15222c21f")
]

# Bash recipe for building across all platforms
script = raw"""
# Update Ninja
cp ${host_prefix}/bin/ninja /usr/bin/ninja

cd ${WORKSPACE}/srcdir/GALAHAD

if [[ "${target}" == *mingw* ]]; then
  LBT="blastrampoline-5"
  HWLOC="hwloc-15"
else
  LBT="blastrampoline"
  HWLOC="hwloc"
fi

QUADRUPLE="true"
if [[ "${target}" == *arm* ]] || [[ "${target}" == *aarch64-linux* ]] || [[ "${target}" == *aarch64-unknown-freebsd* ]] || [[ "${target}" == *powerpc64le-linux-gnu* ]] || [[ "${target}" == *riscv64* ]]; then
    QUADRUPLE="false"
fi

meson setup builddir_int32 --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson \
                           --prefix=$prefix \
                           -Dint64=false \
                           -Dlibhwloc=$HWLOC \
                           -Dlibblas=$LBT \
                           -Dliblapack=$LBT \
                           -Dlibsmumps=smumps \
                           -Dlibdmumps=dmumps \
                           -Dlibcutest_single=cutest_single \
                           -Dlibcutest_double=cutest_double \
                           -Dlibcutest_quadruple= \
                           -Dlibcutest_modules=$prefix/modules \
                           -Dsingle=true \
                           -Ddouble=true \
                           -Dquadruple=false \
                           -Dbinaries=true \
                           -Dtests=false \
                           -Dlibhsl=hsl_subset \
                           -Dlibhsl_modules=$prefix/modules

meson compile -C builddir_int32

meson setup builddir_int64 --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson \
                           --prefix=$prefix \
                           -Dint64=true \
                           -Dlibhwloc=$HWLOC \
                           -Dlibblas=$LBT \
                           -Dliblapack=$LBT \
                           -Dlibsmumps= \
                           -Dlibdmumps= \
                           -Dlibcutest_single= \
                           -Dlibcutest_double= \
                           -Dlibcutest_quadruple= \
                           -Dlibcutest_modules=$prefix/modules \
                           -Dsingle=true \
                           -Ddouble=true \
                           -Dquadruple=false \
                           -Dbinaries=false \
                           -Dtests=false \
                           -Dlibhsl=hsl_subset_64 \
                           -Dlibhsl_modules=$prefix/modules

meson compile -C builddir_int64

if [[ "$QUADRUPLE" == "true" ]]; then
    meson setup builddir_quad_int32 --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson \
                                    --prefix=$prefix \
                                    -Dint64=false \
                                    -Dlibhwloc=$HWLOC \
                                    -Dlibblas= \
                                    -Dliblapack= \
                                    -Dlibsmumps= \
                                    -Dlibdmumps= \
                                    -Dlibcutest_single=cutest_single \
                                    -Dlibcutest_double=cutest_double \
                                    -Dlibcutest_quadruple= \
                                    -Dlibcutest_modules=$prefix/modules \
                                    -Dsingle=false \
                                    -Ddouble=false \
                                    -Dquadruple=true \
                                    -Dbinaries=false \
                                    -Dtests=false \
                                    -Dlibhsl=hsl_subset \
                                    -Dlibhsl_modules=$prefix/modules

    meson compile -C builddir_quad_int32

    meson setup builddir_quad_int64 --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson \
                                    --prefix=$prefix \
                                    -Dint64=true \
                                    -Dlibhwloc=$HWLOC \
                                    -Dlibblas= \
                                    -Dliblapack= \
                                    -Dlibsmumps= \
                                    -Dlibdmumps= \
                                    -Dlibcutest_single= \
                                    -Dlibcutest_double= \
                                    -Dlibcutest_quadruple= \
                                    -Dlibcutest_modules=$prefix/modules \
                                    -Dsingle=false \
                                    -Ddouble=false \
                                    -Dquadruple=true \
                                    -Dbinaries=false \
                                    -Dtests=false \
                                    -Dlibhsl=hsl_subset_64 \
                                    -Dlibhsl_modules=$prefix/modules

    meson compile -C builddir_quad_int64
fi

meson install -C builddir_int32
meson install -C builddir_int64
if [[ "$QUADRUPLE" == "true" ]]; then
    meson install -C builddir_quad_int32
    meson install -C builddir_quad_int64
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = filter(p -> libgfortran_version(p) != v"3", platforms)
platforms = filter(p -> libgfortran_version(p) != v"4", platforms)
platforms = filter(p -> libc(p) != "musl", platforms)
platforms = filter(p -> nbits(p) != 32, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgalahad_single", :libgalahad_single),
    LibraryProduct("libgalahad_double", :libgalahad_double),
    LibraryProduct("libgalahad_single_64", :libgalahad_single_64),
    LibraryProduct("libgalahad_double_64", :libgalahad_double_64),
    # LibraryProduct("libgalahad_quadruple", :libgalahad_quadruple), <-- not available on all platforms
    # LibraryProduct("libgalahad_quadruple_64", :libgalahad_quadruple_64), <-- not available on all platforms
    ExecutableProduct("buildspec", :buildspec),
    ExecutableProduct("galahad_error", :galahad_error),
    ExecutableProduct("runarc_sif_single", :runarc_sif_single),
    ExecutableProduct("runarc_sif_double", :runarc_sif_double),
    ExecutableProduct("runbgo_sif_single", :runbgo_sif_single),
    ExecutableProduct("runbgo_sif_double", :runbgo_sif_double),
    ExecutableProduct("runblls_sif_single", :runblls_sif_single),
    ExecutableProduct("runblls_sif_double", :runblls_sif_double),
    ExecutableProduct("runbllsb_sif_single", :runbllsb_sif_single),
    ExecutableProduct("runbllsb_sif_double", :runbllsb_sif_double),
    ExecutableProduct("runbqp_qplib_single", :runbqp_qplib_single),
    ExecutableProduct("runbqp_qplib_double", :runbqp_qplib_double),
    ExecutableProduct("runbqp_sif_single", :runbqp_sif_single),
    ExecutableProduct("runbqp_sif_double", :runbqp_sif_double),
    ExecutableProduct("runbqpb_qplib_single", :runbqpb_qplib_single),
    ExecutableProduct("runbqpb_qplib_double", :runbqpb_qplib_double),
    ExecutableProduct("runbqpb_sif_single", :runbqpb_sif_single),
    ExecutableProduct("runbqpb_sif_double", :runbqpb_sif_double),
    ExecutableProduct("runccqp_qplib_single", :runccqp_qplib_single),
    ExecutableProduct("runccqp_qplib_double", :runccqp_qplib_double),
    ExecutableProduct("runccqp_sif_single", :runccqp_sif_single),
    ExecutableProduct("runccqp_sif_double", :runccqp_sif_double),
    ExecutableProduct("runclls_sif_single", :runclls_sif_single),
    ExecutableProduct("runclls_sif_double", :runclls_sif_double),
    ExecutableProduct("runcdqp_qplib_single", :runcdqp_qplib_single),
    ExecutableProduct("runcdqp_qplib_double", :runcdqp_qplib_double),
    ExecutableProduct("runcdqp_sif_single", :runcdqp_sif_single),
    ExecutableProduct("runcdqp_sif_double", :runcdqp_sif_double),
    ExecutableProduct("runcqp_qplib_single", :runcqp_qplib_single),
    ExecutableProduct("runcqp_qplib_double", :runcqp_qplib_double),
    ExecutableProduct("runcqp_sif_single", :runcqp_sif_single),
    ExecutableProduct("runcqp_sif_double", :runcqp_sif_double),
    ExecutableProduct("rundemo_sif_single", :rundemo_sif_single),
    ExecutableProduct("rundemo_sif_double", :rundemo_sif_double),
    ExecutableProduct("rundgo_sif_single", :rundgo_sif_single),
    ExecutableProduct("rundgo_sif_double", :rundgo_sif_double),
    ExecutableProduct("rundlp_qplib_single", :rundlp_qplib_single),
    ExecutableProduct("rundlp_qplib_double", :rundlp_qplib_double),
    ExecutableProduct("rundlp_sif_single", :rundlp_sif_single),
    ExecutableProduct("rundlp_sif_double", :rundlp_sif_double),
    ExecutableProduct("rundps_sif_single", :rundps_sif_single),
    ExecutableProduct("rundps_sif_double", :rundps_sif_double),
    ExecutableProduct("rundqp_qplib_single", :rundqp_qplib_single),
    ExecutableProduct("rundqp_qplib_double", :rundqp_qplib_double),
    ExecutableProduct("rundqp_sif_single", :rundqp_sif_single),
    ExecutableProduct("rundqp_sif_double", :rundqp_sif_double),
    ExecutableProduct("runeqp_sif_single", :runeqp_sif_single),
    ExecutableProduct("runeqp_sif_double", :runeqp_sif_double),
    ExecutableProduct("runexpo_sif_single", :runexpo_sif_single),
    ExecutableProduct("runexpo_sif_double", :runexpo_sif_double),
    ExecutableProduct("runfdh_sif_single", :runfdh_sif_single),
    ExecutableProduct("runfdh_sif_double", :runfdh_sif_double),
    ExecutableProduct("runfiltrane_sif_single", :runfiltrane_sif_single),
    ExecutableProduct("runfiltrane_sif_double", :runfiltrane_sif_double),
    ExecutableProduct("rungltr_sif_single", :rungltr_sif_single),
    ExecutableProduct("rungltr_sif_double", :rungltr_sif_double),
    ExecutableProduct("runglrt_sif_single", :runglrt_sif_single),
    ExecutableProduct("runglrt_sif_double", :runglrt_sif_double),
    ExecutableProduct("runl1qp_sif_single", :runl1qp_sif_single),
    ExecutableProduct("runl1qp_sif_double", :runl1qp_sif_double),
    ExecutableProduct("runl2rt_sif_single", :runl2rt_sif_single),
    ExecutableProduct("runl2rt_sif_double", :runl2rt_sif_double),
    ExecutableProduct("runlancelot_sif_single", :runlancelot_sif_single),
    ExecutableProduct("runlancelot_sif_double", :runlancelot_sif_double),
    ExecutableProduct("run_lancelot_simple_single", :run_lancelot_simple_single),
    ExecutableProduct("run_lancelot_simple_double", :run_lancelot_simple_double),
    ExecutableProduct("runlancelot_steering_sif_single", :runlancelot_steering_sif_single),
    ExecutableProduct("runlancelot_steering_sif_double", :runlancelot_steering_sif_double),
    ExecutableProduct("runlls_sif_single", :runlls_sif_single),
    ExecutableProduct("runlls_sif_double", :runlls_sif_double),
    ExecutableProduct("runlpb_qplib_single", :runlpb_qplib_single),
    ExecutableProduct("runlpb_qplib_double", :runlpb_qplib_double),
    ExecutableProduct("runlpb_sif_single", :runlpb_sif_single),
    ExecutableProduct("runlpb_sif_double", :runlpb_sif_double),
    ExecutableProduct("runlpa_qplib_single", :runlpa_qplib_single),
    ExecutableProduct("runlpa_qplib_double", :runlpa_qplib_double),
    ExecutableProduct("runlpa_sif_single", :runlpa_sif_single),
    ExecutableProduct("runlpa_sif_double", :runlpa_sif_double),
    ExecutableProduct("runlpqp_sif_single", :runlpqp_sif_single),
    ExecutableProduct("runlpqp_sif_double", :runlpqp_sif_double),
    ExecutableProduct("runlqr_sif_single", :runlqr_sif_single),
    ExecutableProduct("runlqr_sif_double", :runlqr_sif_double),
    ExecutableProduct("runlqt_sif_single", :runlqt_sif_single),
    ExecutableProduct("runlqt_sif_double", :runlqt_sif_double),
    ExecutableProduct("runlsrt_sif_single", :runlsrt_sif_single),
    ExecutableProduct("runlsrt_sif_double", :runlsrt_sif_double),
    ExecutableProduct("runlstr_sif_single", :runlstr_sif_single),
    ExecutableProduct("runlstr_sif_double", :runlstr_sif_double),
    ExecutableProduct("runmiqr_sif_single", :runmiqr_sif_single),
    ExecutableProduct("runmiqr_sif_double", :runmiqr_sif_double),
    ExecutableProduct("runnls_sif_single", :runnls_sif_single),
    ExecutableProduct("runnls_sif_double", :runnls_sif_double),
    ExecutableProduct("runnodend_sif_single", :runnodend_sif_single),
    ExecutableProduct("runnodend_sif_double", :runnodend_sif_double),
    ExecutableProduct("runpresolve_sif_single", :runpresolve_sif_single),
    ExecutableProduct("runpresolve_sif_double", :runpresolve_sif_double),
    ExecutableProduct("runqp_qplib_single", :runqp_qplib_single),
    ExecutableProduct("runqp_qplib_double", :runqp_qplib_double),
    ExecutableProduct("runqp_sif_single", :runqp_sif_single),
    ExecutableProduct("runqp_sif_double", :runqp_sif_double),
    ExecutableProduct("runqpa_qplib_single", :runqpa_qplib_single),
    ExecutableProduct("runqpa_qplib_double", :runqpa_qplib_double),
    ExecutableProduct("runqpa_sif_single", :runqpa_sif_single),
    ExecutableProduct("runqpa_sif_double", :runqpa_sif_double),
    ExecutableProduct("runqpb_qplib_single", :runqpb_qplib_single),
    ExecutableProduct("runqpb_qplib_double", :runqpb_qplib_double),
    ExecutableProduct("runqpb_sif_single", :runqpb_sif_single),
    ExecutableProduct("runqpb_sif_double", :runqpb_sif_double),
    ExecutableProduct("runqpc_qplib_single", :runqpc_qplib_single),
    ExecutableProduct("runqpc_qplib_double", :runqpc_qplib_double),
    ExecutableProduct("runqpc_sif_single", :runqpc_sif_single),
    ExecutableProduct("runqpc_sif_double", :runqpc_sif_double),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="Ninja_jll", uuid="76642167-d241-5cee-8c94-7a494e8cb7b7")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8")),
    Dependency(PackageSpec(name="MUMPS_seq_jll", uuid="d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d")),
    Dependency(PackageSpec(name="HSL_jll", uuid="017b0a0e-03f4-516a-9b91-836bbd1904dd")),
    Dependency(PackageSpec(name="CUTEst_jll", uuid="bb5f6f25-f23d-57fd-8f90-3ef7bad1d825"), compat="2.5.6"),
    # Dependency(PackageSpec(name="PaStiX_jll", uuid="46e5285b-ff06-5712-adf2-cc145d39f096")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"9.1.0", julia_compat="1.9")
