# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "Trilinos"
version = v"16.2.1"

# Collection of sources required to complete build.
sources = [
    GitSource("https://github.com/trilinos/Trilinos.git", "cf47480689f48aafd08983987d7ba083cff1654e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms.
script = raw"""
cd ${WORKSPACE}/srcdir/Trilinos
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/kokkostpl.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mpi-constants.patch

install_license LICENSE

if [[ "${target}" == *-mingw* ]]; then
    BLAS_NAME=libblastrampoline-5
else
    BLAS_NAME=libblastrampoline
fi

# Use newer CMake from the HostBuildDependency.
rm -f /usr/bin/cmake

# Delete compiler settings from the toolchain file so Trilinos can detect the
# MPI wrappers provided by the selected Yggdrasil MPI dependency.
sed -i '/CMAKE_C_COMPILER/d' ${CMAKE_TARGET_TOOLCHAIN}
sed -i '/CMAKE_CXX_COMPILER/d' ${CMAKE_TARGET_TOOLCHAIN}

# TODO: MPITrampoline embeds the wrong CC. https://github.com/JuliaPackaging/Yggdrasil/issues/7420
export MPITRAMPOLINE_CC="$(which ${CC})"
export MPITRAMPOLINE_CXX="$(which ${CXX})"
export MPITRAMPOLINE_FC="$(which ${FC})"

export CMAKE_PREFIX_PATH="${prefix}:${libdir}/cmake:${CMAKE_PREFIX_PATH:-}"

UMFPACK_CONFIG="$(find "${prefix}" -name UMFPACKConfig.cmake -print -quit 2>/dev/null || true)"
SUITESPARSE_CONFIG="$(find "${prefix}" -name SuiteSparseConfig.cmake -print -quit 2>/dev/null || true)"
UMFPACK_DIR_FLAG=()
if [[ -n "${UMFPACK_CONFIG}" ]]; then
    UMFPACK_DIR="$(dirname "${UMFPACK_CONFIG}")"
    UMFPACK_DIR_FLAG=("-DUMFPACK_DIR=${UMFPACK_DIR}")
    echo "Using UMFPACK_DIR=${UMFPACK_DIR}"
elif [[ -n "${SUITESPARSE_CONFIG}" ]]; then
    UMFPACK_DIR="$(dirname "${SUITESPARSE_CONFIG}")"
    UMFPACK_DIR_FLAG=("-DUMFPACK_DIR=${UMFPACK_DIR}")
    echo "Using SuiteSparse CMake package directory for UMFPACK_DIR=${UMFPACK_DIR}"
else
    echo "No SuiteSparse CMake package config found; using explicit UMFPACK include/library fallback"
fi

SUITESPARSE_INCLUDE_DIRS=()
for dir in "${prefix}/include/suitesparse" "${prefix}/include"; do
    if [[ -f "${dir}/umfpack.h" ]]; then
        SUITESPARSE_INCLUDE_DIRS+=("${dir}")
        break
    fi
done
if [[ ${#SUITESPARSE_INCLUDE_DIRS[@]} -eq 0 ]]; then
    echo "Could not locate umfpack.h under ${prefix}/include" >&2
    exit 1
fi

SUITESPARSE_LIBS=()
missing=()
for lib in umfpack amd suitesparseconfig; do
    if [[ -f "${libdir}/lib${lib}.${dlext}" ]]; then
        SUITESPARSE_LIBS+=("${libdir}/lib${lib}.${dlext}")
    elif [[ -f "${libdir}/lib${lib}.a" ]]; then
        SUITESPARSE_LIBS+=("${libdir}/lib${lib}.a")
    else
        missing+=("${lib}")
    fi
done
if [[ ${#missing[@]} -ne 0 ]]; then
    echo "Could not locate SuiteSparse libraries: ${missing[*]} under ${libdir}" >&2
    exit 1
fi

NETCDF_INCLUDE_DIRS=()
for dir in "${prefix}/include"; do
    if [[ -f "${dir}/netcdf.h" ]]; then
        NETCDF_INCLUDE_DIRS+=("${dir}")
        break
    fi
done

NETCDF_LIBS=()
if [[ -f "${libdir}/libnetcdf.${dlext}" ]]; then
    NETCDF_LIBS+=("${libdir}/libnetcdf.${dlext}")
elif [[ -f "${libdir}/libnetcdf.a" ]]; then
    NETCDF_LIBS+=("${libdir}/libnetcdf.a")
fi

NETCDF_ARGS=()
if [[ ${#NETCDF_INCLUDE_DIRS[@]} -eq 0 || ${#NETCDF_LIBS[@]} -eq 0 ]]; then
    echo "NetCDF artifact not available for ${target}; disabling Trilinos NetCDF TPL"
    NETCDF_ARGS+=("-DTPL_ENABLE_Netcdf=OFF")
else
    NETCDF_ARGS+=("-DTPL_ENABLE_Netcdf=ON")
    NETCDF_ARGS+=("-DTPL_Netcdf_INCLUDE_DIRS=$(IFS=';'; echo "${NETCDF_INCLUDE_DIRS[*]}")")
    NETCDF_ARGS+=("-DTPL_Netcdf_LIBRARIES=$(IFS=';'; echo "${NETCDF_LIBS[*]}")")
fi

cmake -S . -B build -G "Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DTrilinos_ENABLE_OpenMP=ON \
    -DTrilinos_ENABLE_ALL_PACKAGES=OFF \
    -DTrilinos_ENABLE_SECONDARY_TESTED_CODE=ON \
    -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF \
    -DTrilinos_ENABLE_TESTS=OFF \
    -DTrilinos_ENABLE_EXPLICIT_INSTANTIATION=ON \
    -DTrilinos_ENABLE_Amesos2=ON \
    -DTrilinos_ENABLE_Anasazi=ON \
    -DTrilinos_ENABLE_Belos=ON \
    -DTrilinos_ENABLE_Galeri=ON \
    -DTrilinos_ENABLE_Intrepid2=ON \
    -DTrilinos_ENABLE_Ifpack2=ON \
    -DTrilinos_ENABLE_KokkosKernels=ON \
    -DTrilinos_ENABLE_MueLu=ON \
    -DTrilinos_ENABLE_NOX=ON \
    -DTrilinos_ENABLE_Panzer=ON \
    -DTrilinos_ENABLE_Phalanx=ON \
    -DTrilinos_ENABLE_Piro=ON \
    -DTrilinos_ENABLE_ROL=ON \
    -DTrilinos_ENABLE_Sacado=ON \
    -DTrilinos_ENABLE_Shards=ON \
    -DTrilinos_ENABLE_ShyLU_DDFROSch=ON \
    -DTrilinos_ENABLE_Stokhos=ON \
    -DTrilinos_ENABLE_Stratimikos=ON \
    -DTrilinos_ENABLE_Teko=ON \
    -DTrilinos_ENABLE_Teuchos=ON \
    -DTrilinos_ENABLE_Tempus=ON \
    -DTrilinos_ENABLE_Thyra=ON \
    -DTrilinos_ENABLE_Tpetra=ON \
    -DTrilinos_ENABLE_Xpetra=ON \
    -DTrilinos_ENABLE_Zoltan2=ON \
    -DTrilinos_ENABLE_TrilinosFrameworkTests=OFF \
    -DTrilinos_ENABLE_TrilinosATDMConfigTests=OFF \
    -DTrilinos_ENABLE_TrilinosBuildStats=OFF \
    -DTrilinos_ENABLE_TrilinosInstallTests=OFF \
    -DTrilinos_ENABLE_PyTrilinos=OFF \
    -DTrilinos_ENABLE_PyTrilinos2=OFF \
    -DTrilinos_ENABLE_WebTrilinos=OFF \
    -DTrilinos_ENABLE_Optika=OFF \
    -DTrilinos_ENABLE_NewPackage=OFF \
    -DTpetra_ENABLE_DEPRECATED_CODE=ON \
    -DXpetra_ENABLE_DEPRECATED_CODE=ON \
    -DTPL_ENABLE_MPI=ON \
    -DTPL_ENABLE_Kokkos=ON \
    -DTPL_ENABLE_BLAS=ON \
    -DTPL_ENABLE_LAPACK=ON \
    -DTPL_ENABLE_UMFPACK=ON \
    "${UMFPACK_DIR_FLAG[@]}" \
    -DTPL_UMFPACK_INCLUDE_DIRS="$(IFS=';'; echo "${SUITESPARSE_INCLUDE_DIRS[*]}")" \
    -DTPL_UMFPACK_LIBRARIES="$(IFS=';'; echo "${SUITESPARSE_LIBS[*]}")" \
    -DTPL_ENABLE_Boost=ON \
    -DTPL_Boost_INCLUDE_DIRS="${prefix}/include" \
    "${NETCDF_ARGS[@]}" \
    -DTPL_ENABLE_Matio=ON \
    -DTPL_ENABLE_X11=OFF \
    -DBLAS_LIBRARY_DIRS="${prefix}/lib" \
    -DBLAS_LIBRARY_NAMES="${BLAS_NAME}.${dlext}" \
    -DLAPACK_LIBRARY_DIRS="${prefix}/lib" \
    -DLAPACK_LIBRARY_NAMES="${BLAS_NAME}.${dlext}" \
    -DHAVE_GCC_ABI_DEMANGLE_EXITCODE=0 \
    -DHAVE_TEUCHOS_BLASFLOAT_EXITCODE=0 \
    -DHAVE_TEUCHOS_BLASFLOAT_DOUBLE_RETURN_EXITCODE=0 \
    -DCXX_COMPLEX_BLAS_WORKS_EXITCODE=0 \
    -DLAPACK_SLAPY2_WORKS_EXITCODE=0 \
    -DHAVE_TEUCHOS_LAPACKLARND_EXITCODE=0 \
    -DKK_BLAS_RESULT_AS_POINTER_ARG_EXITCODE=0 \
    -DRUN_RESULT=0 \
    -DHAVE_GCC_ABI_DEMANGLE_EXITCODE__TRYRUN_OUTPUT='' \
    -DHAVE_TEUCHOS_BLASFLOAT_EXITCODE__TRYRUN_OUTPUT='' \
    -DLAPACK_SLAPY2_WORKS_EXITCODE__TRYRUN_OUTPUT='' \
    -DCXX_COMPLEX_BLAS_WORKS_EXITCODE__TRYRUN_OUTPUT='' \
    -DHAVE_TEUCHOS_LAPACKLARND_EXITCODE__TRYRUN_OUTPUT='' \
    -DKK_BLAS_RESULT_AS_POINTER_ARG_EXITCODE__TRYRUN_OUTPUT='' \
    -DRUN_RESULT__TRYRUN_OUTPUT=OFF

# The full Trilinos package set has several very large C++ translation units.
# Keep parallelism conservative so local validation and CI workers do not get
# killed by memory pressure mid-build.
cmake --build build --parallel 2
cmake --install build

echo "Installed Trilinos libraries:"
find "${libdir}" -maxdepth 1 -type f \( -name "libtrilinos*.${dlext}" -o -name "libamesos2*.${dlext}" -o -name "libbelos*.${dlext}" -o -name "libifpack2*.${dlext}" -o -name "libmuelu*.${dlext}" -o -name "libshylu*.${dlext}" -o -name "libstratimikos*.${dlext}" -o -name "libteuchos*.${dlext}" -o -name "libtpetra*.${dlext}" -o -name "libxpetra*.${dlext}" \) -print | sort
test -f "${libdir}/cmake/Trilinos/TrilinosConfig.cmake"
"""

# Start with the single platform requested for local validation. Broaden only
# after the Linux GNU build is known to configure, build, and link.
platforms = supported_platforms()
filter!(p -> arch(p) == "x86_64" && Sys.islinux(p) && libc(p) == "glibc", platforms)
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)
filter!(p -> !(p["libgfortran_version"] in ("3.0.0", "4.0.0")), platforms)

# MPI handling.
augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we ensure are always present from the broad but explicit
# modern Kokkos/Tpetra-focused package set above.
products = [
    LibraryProduct("libamesos2", :libamesos2),
    LibraryProduct("libbelos", :libbelos),
    LibraryProduct("libgaleri-xpetra", :libgaleri_xpetra),
    LibraryProduct("libifpack2", :libifpack2),
    LibraryProduct("libmuelu", :libmuelu),
    LibraryProduct("libshylu_ddfrosch", :libshylu_ddfrosch),
    LibraryProduct("libstratimikos", :libstratimikos),
    LibraryProduct("libteuchoscomm", :libteuchoscomm),
    LibraryProduct("libteuchoscore", :libteuchoscore),
    LibraryProduct("libteuchosnumerics", :libteuchosnumerics),
    LibraryProduct("libteuchosparameterlist", :libteuchosparameterlist),
    LibraryProduct("libtpetra", :libtpetra),
    LibraryProduct("libxpetra", :libxpetra),
]

# Dependencies that must be installed before this package can be built.
dependencies = [
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"); compat="7.12.1"),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93")),
    Dependency(PackageSpec(name="Kokkos_jll", uuid="c1216c3d-6bb3-5a2b-bbbf-529b35eba709"); compat="~4.7.4"),
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"); compat="=1.87.0"),
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3")),
    Dependency(PackageSpec(name="Matio_jll", uuid="f34749e5-bf11-50ef-9bf7-447477e32da8"); compat="v1.5.24"),
    # For libfortran, and for libgomp used by Kokkos OpenMP on Linux.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    HostBuildDependency(PackageSpec(name="CMake_jll", uuid="3f4e10e2-61f2-5801-8945-23b9d642d0e6")),
]

append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.10", augment_platform_block)
