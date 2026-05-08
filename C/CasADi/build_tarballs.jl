using BinaryBuilder, Pkg

name = "CasADi"

version = v"3.7.2"

sources = [
    GitSource(
        "https://github.com/casadi/casadi.git",
        "f959d3175a444d763e4eda4aece48f4c5f4a6f90",
    ),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/casadi
install_license LICENSE.txt
mkdir -p build
cd build

CXX_STANDARD="-std=c++11"
CMAKE_CXX_STANDARD="11"
if [[ "${target}" == *"mingw"* ]]; then
    CXX_STANDARD="-std=c++14"
    CMAKE_CXX_STANDARD="14"
fi

export CXXFLAGS="-fPIC ${CXX_STANDARD}"
export CFLAGS="${CFLAGS} -fPIC"

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_INSTALL_BINDIR=${bindir} \
    -DCMAKE_INSTALL_LIBDIR=${libdir} \
    -DCMAKE_INSTALL_INCLUDEDIR=${includedir} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD} \
    -DWITH_IPOPT=ON \
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
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
filter!(p -> arch(p) != "riscv64" && 
    !(arch(p) == "aarch64" && Sys.isfreebsd(p)),
    platforms)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Ipopt_jll"; compat="300.1400.400"),
]

products = [
    ExecutableProduct("amplexe", :amplexe),
    LibraryProduct("libcasadi", :libcasadi),
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
