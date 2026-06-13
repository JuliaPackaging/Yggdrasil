# Yggdrasil recipe for CasADi — FORK of JuliaPackaging/Yggdrasil C/CasADi.
#
# Differences from upstream C/CasADi:
#   * version  -> 3.8.0-beta1 (casadi nightly / Julia-bindings beta)
#   * source   -> the casadi nightly-main SOURCE BUNDLE (not git): it carries the
#                 pre-generated SWIG -julia wrapper (swig/julia/target/source/
#                 casadiJULIA_wrap.cxx + casadi.jl) + CasADiNative.jl, so the
#                 wrapper builds in SWIG_IMPORT mode (no patched SWIG in the BB
#                 toolchain).  URL hardcoded for the beta.
#   * adds the Julia wrapper product `libcasadi_wrap` (build-once: the marshaling
#                 is de-inlined => ABI-portable across the Julia 1.11 Memory-array
#                 boundary, so NO julia_version platform augmentation).
#
# STATUS: draft — not yet run through BinaryBuilder. Validate on a real Yggdrasil
# PR. Two spots need BB confirmation (see inline TODO): the libjulia_jll header
# dependency, and Windows DLL linking of the wrapper.

using BinaryBuilder, Pkg

name = "CasADi"
version = v"3.8.0-beta1"

sources = [
    ArchiveSource(
        "https://github.com/casadi/casadi/releases/download/nightly-main/casadi-source-vmain.zip",
        "02f4e0497c3cbe1f0a3f6cc73201f56547c651960b09ed3717a44760350778da",
    ),
    DirectorySource("./bundled"),   # amplexe main.cpp (from upstream recipe)
]

script = raw"""
# The source bundle extracts to the srcdir ROOT (CMakeLists.txt, casadi/, swig/ here).
cd $WORKSPACE/srcdir
install_license LICENSE.txt
mkdir -p build
cd build

CXX_STANDARD="-std=c++11"
CMAKE_CXX_STANDARD="11"
if [[ "${target}" == *"mingw"* ]]; then
    CXX_STANDARD="-std=c++14"
    CMAKE_CXX_STANDARD="14"
fi

export CXXFLAGS="-fPIC ${CXX_STANDARD} -I${includedir}/coin-or"
export CFLAGS="${CFLAGS} -fPIC"

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_INSTALL_BINDIR=${bindir} \
    -DCMAKE_INSTALL_LIBDIR=${libdir} \
    -DCMAKE_INSTALL_INCLUDEDIR=${includedir} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD} \
    -DWITH_IPOPT=ON \
    -DWITH_BONMIN=ON \
    -DWITH_EXAMPLES=OFF \
    -DWITH_DEEPBIND=OFF \
    ..

make -j ${nproc}
make install

# ---- amplexe (unchanged from upstream CasADi recipe) ----
cd $WORKSPACE/srcdir
c++ main.cpp -o "${bindir}/amplexe${exeext}" \
    -I"${includedir}" -L"${libdir}" -lcasadi ${CXX_STANDARD}

# ---- Julia wrapper: libcasadi_wrap (SWIG_IMPORT: compile the pre-generated
# casadiJULIA_wrap.cxx).  Build-once: the wrapper has no jl_array_t layout reads,
# so one binary spans Julia 1.10..1.12 (the de-inline removed the 1.11 coupling).
# jl_* resolve at dlopen from the host julia process; on unix the wrapper does NOT
# link libjulia. casadi.jl dlopens it as libcasadi_wrap.${dlext}. ----
JL_INC="${includedir}/julia"
WRAP="$WORKSPACE/srcdir/swig/julia/target/source/casadiJULIA_wrap.cxx"
WRAP_FLAGS="-std=c++17 -fPIC -shared -DWITH_DEPRECATED_FEATURES -I${includedir} -I${JL_INC} ${WRAP} -L${libdir} -lcasadi"
if [[ "${target}" == *"apple"* ]]; then
    # macOS: leave jl_* undefined, resolved from the loading julia process.
    WRAP_FLAGS="${WRAP_FLAGS} -undefined dynamic_lookup"
elif [[ "${target}" == *"mingw"* ]]; then
    # TODO(BB): Windows DLLs must resolve imports at link time, so the wrapper
    # links the libjulia import lib here -> on Windows it is coupled to that
    # libjulia ABI (not truly build-once). Revisit (delay-load, or drop Windows
    # from v0.1) when validating the PR.
    WRAP_FLAGS="${WRAP_FLAGS} -ljulia"
fi
c++ ${WRAP_FLAGS} -o "${libdir}/libcasadi_wrap.${dlext}"

# Ship the Julia sources so LibCasADi.jl can vendor/load them.
install -Dm644 "$WORKSPACE/srcdir/swig/julia/target/source/casadi.jl" \
    "${prefix}/share/julia/casadi/casadi.jl"
install -Dm644 "$WORKSPACE/srcdir/swig/julia/CasADiNative.jl" \
    "${prefix}/share/julia/casadi/CasADiNative.jl"
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
filter!(p -> arch(p) != "riscv64" && !Sys.isfreebsd(p), platforms)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Ipopt_jll"; compat="300.1400.1901"),
    Dependency("Bonmin_jll"; compat="100.800.902"),
    # julia.h for the wrapper compile. Pinned to the OLDEST supported Julia so the
    # build-once binary runs on >= that ABI. Headers-only on unix (jl_* resolve at
    # dlopen); used as a plain BuildDependency -> NO augment_platform!/julia_version
    # matrix (that is the whole point of the de-inline).
    # TODO(BB): confirm libjulia_jll resolves as a version-pinned BuildDependency
    # without triggering the julia_version platform augmentation.
    BuildDependency(PackageSpec(name="libjulia_jll", version=v"1.10.0")),
]

products = [
    ExecutableProduct("amplexe", :amplexe),
    LibraryProduct("libcasadi", :libcasadi),
    LibraryProduct("libcasadi_wrap", :libcasadi_wrap),   # SWIG -julia wrapper (build-once)
    LibraryProduct("libcasadi_conic_ipqp", :libcasadi_conic_ipqp),
    LibraryProduct("libcasadi_conic_nlpsol", :libcasadi_conic_nlpsol),
    LibraryProduct("libcasadi_conic_qrqp", :libcasadi_conic_qrqp),
    LibraryProduct("libcasadi_importer_shell", :libcasadi_importer_shell),
    LibraryProduct("libcasadi_integrator_collocation", :libcasadi_integrator_collocation),
    LibraryProduct("libcasadi_integrator_cvodes", :libcasadi_integrator_cvodes),
    LibraryProduct("libcasadi_integrator_idas", :libcasadi_integrator_idas),
    LibraryProduct("libcasadi_integrator_rk", :libcasadi_integrator_rk),
    LibraryProduct("libcasadi_interpolant_bspline", :libcasadi_interpolant_bspline),
    LibraryProduct("libcasadi_interpolant_linear", :libcasadi_interpolant_linear),
    LibraryProduct("libcasadi_linsol_csparse", :libcasadi_linsol_csparse),
    LibraryProduct("libcasadi_linsol_csparsecholesky", :libcasadi_linsol_csparsecholesky),
    LibraryProduct("libcasadi_linsol_ldl", :libcasadi_linsol_ldl),
    LibraryProduct("libcasadi_linsol_lsqr", :libcasadi_linsol_lsqr),
    LibraryProduct("libcasadi_linsol_qr", :libcasadi_linsol_qr),
    LibraryProduct("libcasadi_linsol_symbolicqr", :libcasadi_linsol_symbolicqr),
    LibraryProduct("libcasadi_linsol_tridiag", :libcasadi_linsol_tridiag),
    LibraryProduct("libcasadi_nlpsol_feasiblesqpmethod", :libcasadi_nlpsol_feasiblesqpmethod),
    LibraryProduct("libcasadi_nlpsol_ipopt", :libcasadi_nlpsol_ipopt),
    LibraryProduct("libcasadi_nlpsol_qrsqp", :libcasadi_nlpsol_qrsqp),
    LibraryProduct("libcasadi_nlpsol_scpgen", :libcasadi_nlpsol_scpgen),
    LibraryProduct("libcasadi_nlpsol_sqpmethod", :libcasadi_nlpsol_sqpmethod),
    LibraryProduct("libcasadi_nlpsol_bonmin", :libcasadi_nlpsol_bonmin),
    LibraryProduct("libcasadi_rootfinder_fast_newton", :libcasadi_rootfinder_fast_newton),
    LibraryProduct("libcasadi_rootfinder_kinsol", :libcasadi_rootfinder_kinsol),
    LibraryProduct("libcasadi_rootfinder_newton", :libcasadi_rootfinder_newton),
    LibraryProduct("libcasadi_rootfinder_nlpsol", :libcasadi_rootfinder_nlpsol),
    LibraryProduct("libcasadi_sundials_common", :libcasadi_sundials_common),
    LibraryProduct("libcasadi_xmlfile_tinyxml", :libcasadi_xmlfile_tinyxml),
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
    preferred_gcc_version = v"8",
    julia_compat = "1.6",
)
