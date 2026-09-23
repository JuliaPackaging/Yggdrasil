# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

# YAC: Yet Another Coupler (DKRZ / MPI-M), https://dkrz-sw.gitlab-pages.dkrz.de/yac/
name = "YAC"
version = v"3.21.0"

sources = [
    GitSource("https://gitlab.dkrz.de/dkrz-sw/yac.git",
              "1f46724b3bcbd479144a79009323d126b6faf604"), # tag v3.21.0
]

script = raw"""
cd ${WORKSPACE}/srcdir/yac

if [[ ${target} == x86_64-linux-musl ]]; then
    # HDF5 (through NetCDF) needs libcurl, and it needs to be the BinaryBuilder
    # libcurl, not the system libcurl. Same for libevent (MPI).
    rm -f /usr/lib/libcurl.* /usr/lib/libevent* /usr/lib/libnghttp2.*
fi

# The CMake build (unlike the Autotools build, which only produces static
# archives) builds shared libraries.
#
# - Only the C API is built: the Fortran bindings would require an `mpi.mod`
#   for every gfortran version, and Julia only uses the C interface.
# - YAC_ENABLE_MPI_CHECKS launches MPI programs at configure time, which is not
#   possible while cross-compiling.
# - LAPACK: YAC only needs a handful of LP64 routines (dgels, dgesv, dgetrf,
#   dgetri, dsytrf, dsytri), called through the Fortran interface (`dgels_`, ...).
#   Use OpenBLAS32 (LP64) for that; libblastrampoline would only forward these
#   LP64 symbols if an LP64 backend is loaded, which Julia does not do by default.
cmake -B build -GNinja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF \
    -DBUILD_TESTING=OFF \
    -DYAC_ENABLE_FORTRAN=OFF \
    -DYAC_ENABLE_PYTHON=OFF \
    -DYAC_ENABLE_EXAMPLES=OFF \
    -DYAC_ENABLE_TOOLS=OFF \
    -DYAC_ENABLE_MCI=ON \
    -DYAC_ENABLE_NETCDF=ON \
    -DYAC_ENABLE_OPENMP=OFF \
    -DYAC_ENABLE_MPI_CHECKS=OFF \
    -DYAC_LAPACK_INTERFACE=system \
    -DBLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" \
    -DLAPACK_LIBRARIES="${libdir}/libopenblas.${dlext}"
cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSES/BSD-3-Clause.txt
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = supported_platforms()
# yaxt (and therefore YAC) is not available on Windows.
filter!(!Sys.iswindows, platforms)
# libfyaml_jll v0.7.12+0 has no builds for riscv64 and aarch64-freebsd yet
# (rebuild in #14897); drop this filter once they are registered.
filter!(p -> !(arch(p) == "riscv64" || (Sys.isfreebsd(p) && arch(p) == "aarch64")), platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# yaxt does not build with MPItrampoline (MPI constants are not compile-time
# constants there), see Y/yaxt.
filter!(p -> p["mpi"] != "mpitrampoline", platforms)

products = [
    # The public C API (yac.h, `yac_c*` functions and `YAC_*` constants)
    LibraryProduct("libyac_mci", :libyac_mci),
    LibraryProduct("libyac_core", :libyac_core),
    LibraryProduct("libyac_utils", :libyac_utils),
    LibraryProduct("libyac_pak", :libyac_pak),
    LibraryProduct("libyac_mtime", :libyac_mtime),
]

dependencies = [
    Dependency("yaxt_jll"; compat="0.12.1"),
    Dependency("libfyaml_jll"; compat="0.7.12"),
    Dependency("NetCDF_jll"; compat="401.1000.101"),
    Dependency("OpenBLAS32_jll"; compat="0.3.34"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]
append!(dependencies, platform_dependencies)

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.10", preferred_gcc_version=v"8")
