using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
# For should_build_platform
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "CasADi"

version = v"3.8.0"

sources = [
    GitSource(
        "https://github.com/casadi/casadi.git",
        "83b3cec864e42c5b64a07e85d4adf91da71458b1",
    ),
    # Vendored so ExternalProject_Add can clone it from disk: Yggdrasil fetches
    # sources outside the sandbox, and CasADi's BUILD_FATROP_GIT_REPO is a cache
    # variable we can redirect at the local checkout.
    GitSource(
        "https://github.com/jgillis/fatrop.git",
        "2d8c5198a47890a55bb872ed4f895484c7769f74",  # v1.1.8.mod
    ),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/casadi
install_license LICENSE.txt

for p in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 "${p}"
done

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

# LAPACK via libblastrampoline, the same BLAS/LAPACK shim that Ipopt_jll,
# Clp_jll and Cbc_jll already link against, so we do not pull a second BLAS
# into the prefix. Pre-setting LAPACK_LIBRARIES makes CasADi skip its
# find_package(LAPACK) (see the `if(NOT LAPACK_LIBRARIES)` in CMakeLists.txt).
# BLAS_LIBRARIES must be set too: external_packages/qpOASES/CMakeLists.txt does
# `target_link_libraries(casadi_qpoases lapack ${BLAS_LIBRARIES})`, and an unset
# BLAS_LIBRARIES expands to FALSE, which reaches the linker as -lFALSE.
if [[ "${target}" == *mingw* ]]; then
    LBT="${libdir}/libblastrampoline-5.${dlext}"
else
    LBT="${libdir}/libblastrampoline.${dlext}"
fi

# OSQP_jll installs a single- and a double-precision build into one prefix, and
# the single one lands last: lib/cmake/osqp points osqp::osqp at
# libosqp_builtin_single, and include/osqp/osqp_configure.h carries
# `#define OSQP_USE_FLOAT`, so OSQPFloat is float for everyone. CasADi's
# interface is double-only. Take a private copy of the headers with that define
# removed, and let the patched CMake pick libosqp_builtin_double via
# find_library (CMAKE_DISABLE_FIND_PACKAGE_OSQP keeps the shipped, single-
# precision CMake config from winning first).
# blasfeo_jll installs into <prefix>/blasfeo/{include,lib} rather than straight
# into the prefix, and FindBLASFEO.cmake looks under $BLASFEO. Only x86_64 (all
# OSes) and aarch64 macOS have blasfeo artifacts, so fatrop is limited to those.
FATROP_FLAGS="-DWITH_FATROP=OFF -DWITH_BLASFEO=OFF"
if [[ -d "${prefix}/blasfeo" ]]; then
    export BLASFEO=${prefix}/blasfeo
    FATROP_FLAGS="-DWITH_BLASFEO=ON -DWITH_FATROP=ON -DWITH_BUILD_FATROP=ON"
    FATROP_FLAGS="${FATROP_FLAGS} -DBUILD_FATROP_GIT_REPO=${WORKSPACE}/srcdir/fatrop"
    FATROP_FLAGS="${FATROP_FLAGS} -DBUILD_FATROP_VERSION=2d8c5198a47890a55bb872ed4f895484c7769f74"
    FATROP_FLAGS="${FATROP_FLAGS} -DBUILD_FATROP_GIT_SHALLOW=OFF"
fi

OSQP_INC=${WORKSPACE}/srcdir/osqp-double-include
mkdir -p ${OSQP_INC}
cp -r ${includedir}/osqp ${OSQP_INC}/
sed -i '/^#define OSQP_USE_FLOAT$/d' ${OSQP_INC}/osqp/osqp_configure.h

# cbc.pc carries `-lasl` on every platform, which links fine everywhere except
# Windows: ASL_jll's recipe only ever does `cp libasl.${dlext} ${libdir}`, so on
# mingw it ships libasl.dll with no import library and `-lasl` has nothing to
# resolve against. The ASL symbols are already inside libCbc.dll, so drop it.
if [[ "${target}" == *mingw* ]]; then
    sed -i 's/-lasl//g' ${prefix}/lib/pkgconfig/*.pc
fi

# HiGHS_jll has no powerpc64le build, so the dependency (and this flag) are
# scoped to the platforms where it exists.
HIGHS_FLAG="-DWITH_HIGHS=OFF"
if [[ "${target}" != powerpc64le-* ]]; then
    HIGHS_FLAG="-DWITH_HIGHS=ON"
fi

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_INSTALL_BINDIR=${bindir} \
    -DCMAKE_INSTALL_LIBDIR=${libdir} \
    -DCMAKE_INSTALL_INCLUDEDIR=${includedir} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD} \
    -DWITH_LAPACK=ON \
    -DLAPACK_LIBRARIES="${LBT}" \
    -DBLAS_LIBRARIES="${LBT}" \
    -DWITH_IPOPT=ON \
    -DWITH_BONMIN=ON \
    ${HIGHS_FLAG} \
    ${FATROP_FLAGS} \
    -DWITH_OSQP=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_OSQP=ON \
    -DOSQP_INCLUDE_DIR="${OSQP_INC}/osqp" \
    -DWITH_CLP=ON \
    -DWITH_CBC=ON \
    -DWITH_QPOASES=ON \
    -DWITH_NO_QPOASES_BANNER=ON \
    -DWITH_BLOCKSQP=ON \
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
filter!(p -> arch(p) != "riscv64" && !Sys.isfreebsd(p),
    platforms)

# HiGHS_jll filters out powerpc64le (see H/HiGHS/build_tarballs.jl), so the
# highs plugin exists on every platform except that one.
highs_platforms = filter(p -> arch(p) != "powerpc64le", platforms)

# blasfeo_jll ships x86_64 (linux glibc+musl, windows, macOS) and aarch64 macOS
# only; its artifacts carry a march tag but resolve fine for an untagged
# platform, so CasADi does not need microarchitecture expansion of its own.
fatrop_platforms = filter(p -> arch(p) == "x86_64" || (arch(p) == "aarch64" && Sys.isapple(p)),
    platforms)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Ipopt_jll"; compat="300.1400.1901"),
    Dependency("Bonmin_jll"; compat="100.800.902"),
    Dependency("libblastrampoline_jll"; compat="5.4.0"),
    Dependency("HiGHS_jll"; compat="1.15.1", platforms=highs_platforms),
    Dependency("OSQP_jll"; compat="100.0.0"),
    Dependency("blasfeo_jll"; compat="0.1.4", platforms=fatrop_platforms)
]

products = [
    ExecutableProduct("amplexe", :amplexe),
    LibraryProduct("libcasadi", :libcasadi),
    LibraryProduct("libcasadi_conic_cbc", :libcasadi_conic_cbc),
    LibraryProduct("libcasadi_conic_clp", :libcasadi_conic_clp),
    LibraryProduct("libcasadi_conic_ipqp", :libcasadi_conic_ipqp),
    LibraryProduct("libcasadi_conic_nlpsol", :libcasadi_conic_nlpsol),
    LibraryProduct("libcasadi_conic_osqp", :libcasadi_conic_osqp),
    LibraryProduct("libcasadi_conic_qpoases", :libcasadi_conic_qpoases),
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
    LibraryProduct("libcasadi_linsol_lapacklu", :libcasadi_linsol_lapacklu),
    LibraryProduct("libcasadi_linsol_lapackqr", :libcasadi_linsol_lapackqr),
    LibraryProduct("libcasadi_linsol_ldl", :libcasadi_linsol_ldl),
    LibraryProduct("libcasadi_linsol_lsqr", :libcasadi_linsol_lsqr),
    LibraryProduct("libcasadi_linsol_qr", :libcasadi_linsol_qr),
    LibraryProduct("libcasadi_linsol_symbolicqr", :libcasadi_linsol_symbolicqr),
    LibraryProduct("libcasadi_linsol_tridiag", :libcasadi_linsol_tridiag),
    LibraryProduct("libcasadi_nlpsol_blocksqp", :libcasadi_nlpsol_blocksqp),
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

highs_product = LibraryProduct("libcasadi_conic_highs", :libcasadi_conic_highs)
fatrop_product = LibraryProduct("libcasadi_nlpsol_fatrop", :libcasadi_nlpsol_fatrop)

# One build_tarballs call per platform, so the products list can differ: the
# highs plugin is absent on powerpc64le. This is the same idiom B/blasfeo uses.
for platform in platforms
    should_build_platform(triplet(platform)) || continue
    platform_products = arch(platform) == "powerpc64le" ? products : [products; highs_product]
    if platform in fatrop_platforms
        platform_products = [platform_products; fatrop_product]
    end
    build_tarballs(
        ARGS,
        name,
        version,
        sources,
        script,
        [platform],
        platform_products,
        dependencies;
        preferred_gcc_version = v"8",
        julia_compat = "1.6",
    )
end
