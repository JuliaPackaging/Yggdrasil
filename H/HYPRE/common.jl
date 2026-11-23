using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

version = v"3.2.1"
offset = 0  # bump for rebuilds, reset on a new upstream release
ygg_version = VersionNumber(version.major, version.minor, 100 * version.patch + offset)

sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/hypre-space/hypre.git", "c3feb783b21b3465e30c29e883325aa766a5b8f4"; tag="v$(version)"),
]

function hypre_script(; bigint::Bool)
    return "BIGINT=$(bigint)\n" * raw"""
cd ${WORKSPACE}/srcdir/hypre

if [[ "${target}" == *-mingw* ]]; then
    LBT=-lblastrampoline-5
else
    LBT=-lblastrampoline
fi

CMAKE_ARGS=()
if [[ "${target}" == x86_64-w64-mingw32 ]]; then
    CMAKE_ARGS+=(
        -DMPI_GUESS_LIBRARY_NAME=MSMPI
        -DMPI_C_LIBRARIES=msmpi64
        -DMPI_CXX_LIBRARIES=msmpi64
    )
fi
if [[ ${BIGINT} == true ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/ilp64-blas-names.patch
    CMAKE_ARGS+=(
        -DHYPRE_ENABLE_BIGINT=ON
        # The patch selects the ILP64 interface; hypre's probe for it would have to run a target binary
        -DHYPRE_EXTERNAL_LAPACK_ILP64_OK=ON
        # Name the library libHYPRE64 at link time, so its SONAME, install name and DLL export name carry it
        -DCMAKE_RELEASE_POSTFIX=64
        # HYPRE_jll installs the same header names, and HYPRE_config.h records the integer width
        -DCMAKE_INSTALL_INCLUDEDIR=include/HYPRE64
    )
fi

cmake -S src -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DHYPRE_ENABLE_OPENMP=ON \
    -DHYPRE_ENABLE_HYPRE_BLAS=OFF \
    -DHYPRE_ENABLE_HYPRE_LAPACK=OFF \
    -DTPL_BLAS_LIBRARIES=${LBT} \
    -DTPL_LAPACK_LIBRARIES=${LBT} \
    -DMPI_HOME=${prefix} \
    "${CMAKE_ARGS[@]}"
cmake --build build --parallel ${nproc}
cmake --install build

install_license COPYRIGHT LICENSE-APACHE LICENSE-MIT NOTICE
"""
end

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

function hypre_dependencies(platforms, platform_dependencies)
    return [
        Dependency("libblastrampoline_jll"; compat="5.4.0"),
        Dependency("CompilerSupportLibraries_jll"; compat="1.0.5", platforms=filter(!Sys.isbsd, platforms)),
        # Clang emits __kmpc_dispatch_deinit, which libomp provides from 19 on
        Dependency("LLVMOpenMP_jll"; compat="19.1.7 - 23", platforms=filter(Sys.isbsd, platforms)),
        platform_dependencies...,
    ]
end
