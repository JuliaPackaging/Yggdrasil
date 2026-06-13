using BinaryBuilder, Pkg

# needed for libjulia_platforms, julia_versions and libjulia_julia_compat
include("../../L/libjulia/common.jl")

name = "CasADi"

version = v"3.8.0"

sources = [
    ArchiveSource(
        "https://github.com/casadi/casadi/releases/download/nightly-main/casadi-source-vmain.zip",
        "fa64acd6d1b36ff0ba8e75dd3390c90ef4ef41edb373c1bef93fbc5d288a753a",
    ),
    DirectorySource("./bundled"),
]

script = raw"""
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

#export CXXFLAGS="-fPIC ${CXX_STANDARD}"
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

# Build amplexe
cd $WORKSPACE/srcdir
c++ main.cpp -o "${bindir}/amplexe${exeext}" \
    -I"${includedir}" \
    -L"${libdir}" \
    -lcasadi ${CXX_STANDARD}

# Build the SWIG -julia wrapper (jl_* resolve at dlopen on unix; Windows links libjulia)
WRAP=swig/julia/target/source/casadiJULIA_wrap.cxx
FLAGS="-std=c++17 -fPIC -shared -DWITH_DEPRECATED_FEATURES -I${includedir} -I${includedir}/julia ${WRAP} -L${libdir} -lcasadi"
if [[ "${target}" == *"apple"* ]]; then
    FLAGS="${FLAGS} -undefined dynamic_lookup"
elif [[ "${target}" == *"mingw"* ]]; then
    FLAGS="${FLAGS} -ljulia"
fi
c++ ${FLAGS} -o "${libdir}/libcasadi_wrap.${dlext}"

install -Dm644 swig/julia/target/source/casadi.jl "${prefix}/share/julia/casadi/casadi.jl"
install -Dm644 swig/julia/CasADiNative.jl "${prefix}/share/julia/casadi/CasADiNative.jl"
"""

# libcasadi_wrap inlines version-specific jl_array_* accessors, so it must be
# built once per Julia minor: augment platforms with a julia_version dimension.
# Matrix = Julia minors released in the last 2 years: 1.11 (2024-10) and 1.12
# (2025-10). 1.10 (2023-12) is older; 1.13 is unreleased (beta).
filter!(v -> v.minor in (11, 12), julia_versions)
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)
# libjulia_platforms already drops the platforms libjulia lacks (32-bit musl,
# armv6l/armv7l, ...); CasADi additionally skips riscv64 and freebsd.
filter!(p -> arch(p) != "riscv64" && !Sys.isfreebsd(p), platforms)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Ipopt_jll"; compat="300.1400.1901"),
    Dependency("Bonmin_jll"; compat="100.800.902"),
    BuildDependency(PackageSpec(; name="libjulia_jll", version="1.11.1")),
]

products = [
    ExecutableProduct("amplexe", :amplexe),
    LibraryProduct("libcasadi", :libcasadi),
    # jl_* symbols only resolve inside a host Julia process, so the audit-time
    # dlopen (enabled by the julia_version platform augmentation) hangs/fails.
    LibraryProduct("libcasadi_wrap", :libcasadi_wrap; dont_dlopen=true),
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
    julia_compat = libjulia_julia_compat(julia_versions),
)
