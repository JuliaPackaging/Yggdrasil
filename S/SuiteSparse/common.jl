using BinaryBuilder, Pkg

# Collection of sources required to build SuiteSparse
function suitesparse_sources(version::VersionNumber; kwargs...)
    suitesparse_version_sources = Dict(
        v"5.10.1" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "538273cfd53720a10e34a3d80d3779b607e1ac26")
        ],
        v"7.0.1" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "03350b0faef6b77d965ddb7c3cd3614a45376bfd"),
        ],
        v"7.2.1" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "d6c84f7416eaee0d23d61c6c49ad1b73235d2ea2")
        ],
        v"7.3.0" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "fad1f30fa260975466bb0ad7da1aabf054517399")
        ],
        v"7.4.0" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "df91d7be262e6b5cddf5dd23ff42dec1713e7947")
        ],
        v"7.5.0" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "da5050cd3f6b6a15ec4d7c42b2c1e2dfe4f8ef6e")
        ],
        v"7.5.1" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "71d6d42cb60b533bd001d3e5514e11120919c43a")
        ],
        v"7.6.0" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "1a4d4fb0c399b261f4ed11aa980c6bab754aefa6")
        ],
        v"7.6.1" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "d4dad6c1d0b5cb3e7c5d7d01ef55653713567662")
        ],
        v"7.7.0" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "13806726cbf470914d012d132a85aea1aff9ee77")
        ],
        v"7.8.0" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "58e6558408f6a51c08e35a5557d5e68cae32147e")
        ],
        v"7.8.2" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "c8c3a9de1c8eef54da5ff19fd0bcf7ca6e8bc9de")
        ],
        v"7.8.3" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "d3c4926d2c47fd6ae558e898bfc072ade210a2a1")
        ],
    )
    return Any[
        suitesparse_version_sources[version]...,
    ]
end

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms()

# Disable sanitize build until it is fixed for the latest LLVM
#push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libsuitesparseconfig",   :libsuitesparseconfig),
    LibraryProduct("libamd",                 :libamd),
    LibraryProduct("libbtf",                 :libbtf),
    LibraryProduct("libcamd",                :libcamd),
    LibraryProduct("libccolamd",             :libccolamd),
    LibraryProduct("libcolamd",              :libcolamd),
    LibraryProduct("libcholmod",             :libcholmod),
    LibraryProduct("libldl",                 :libldl),
    LibraryProduct("libklu",                 :libklu),
    LibraryProduct("libumfpack",             :libumfpack),
    LibraryProduct("librbio",                :librbio),
    LibraryProduct("libspqr",                :libspqr),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll",
                           uuid="8e850b90-86db-534c-a0d3-1478176c7d93"),
               v"5.11.0";  # build version
               compat="5.8.0"),
    BuildDependency("LLVMCompilerRT_jll",platforms=[Platform("x86_64", "linux"; sanitize="memory")]),
    # Need the most recent 3.29.3+1 version (or later) to get libblastrampoline support
    HostBuildDependency(PackageSpec(; name="CMake_jll", version = v"3.29.3"))
]

# Generate a common build script for most SuiteSparse packages.
# use_omp=true will enable OpenMP, this may default to true in the future.
# use_cuda=true will enable the CUDA CHOLMOD and CUDA SPQR builds,
# but requires additional set up found in ../SuiteSparse_GPU.
# CMAKE_OPTIONS prepended to this script can be used to pass additional arguments
# for instance -DSUITESPARSE_USE_SYSTEM_*=ON to use pre-existing JLLs for
# certain packages.
# Use PROJECTS_TO_BUILD to specify which projects to build.
function build_script(; use_omp::Bool = false, use_cuda::Bool = false, build_32bit_blas::Bool = false)
    return "USEOMP=$(use_omp)\nUSECUDA=$(use_cuda)\n" * raw"""
cd $WORKSPACE/srcdir/SuiteSparse

# Needs cmake >= 3.29 provided by jll
apk del cmake

FLAGS+=(INSTALL="${prefix}" INSTALL_LIB="${libdir}" INSTALL_INCLUDE="${prefix}/include")

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

if [[ ${nbits} == 64 ]] && [[ ${build_32bit_blas} == false ]]; then
    CMAKE_OPTIONS+=(
        -DBLAS64_SUFFIX="_64"
        -DSUITESPARSE_USE_64BIT_BLAS=YES
    )
else
    CMAKE_OPTIONS+=(
        -DSUITESPARSE_USE_64BIT_BLAS=NO
    )
fi

# some of these are not used for a particular builder
# but most are. BLAS handling is the big one which isn't always used.
# It's likely easier to keep them in common.jl than add them elsewhere.
# TODO: Can BLAS handling be done by upstream now?
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DBUILD_STATIC_LIBS=OFF \
      -DBUILD_TESTING=OFF \
      -DBLA_VENDOR=libblastrampoline \
      -DSUITESPARSE_ENABLE_PROJECTS=${PROJECTS_TO_BUILD} \
      -DSUITESPARSE_DEMOS=OFF \
      -DSUITESPARSE_USE_STRICT=ON \
      -DSUITESPARSE_USE_FORTRAN=OFF \
      -DSUITESPARSE_USE_OPENMP=${USEOMP} \
      -DSUITESPARSE_USE_CUDA=${USECUDA} \
      -DCHOLMOD_PARTITION=ON \
      "${CMAKE_OPTIONS[@]}" \
      ..

cmake --build . --parallel ${nproc}
cmake --install .

# For now, we'll have to adjust the name of the Lbt library on macOS and FreeBSD.
# Eventually, this should be fixed upstream
if [[ ${target} == *-apple-* ]] || [[ ${target} == *freebsd* ]]; then
    echo "-- Modifying library name for libblastrampoline"

    BLAS_NAME=blastrampoline
    for nm in libcholmod libspqr libumfpack; do
        if [[ *"${nm}"* == PROJECTS_TO_BUILD ]]; then
            # Figure out what version it probably latched on to:
            if [[ ${target} == *-apple-* ]]; then
                LBT_LINK=$(otool -L ${libdir}/${nm}.dylib | grep lib${BLAS_NAME} | awk '{ print $1 }')
                install_name_tool -change ${LBT_LINK} @rpath/lib${BLAS_NAME}.dylib ${libdir}/${nm}.dylib
            elif [[ ${target} == *freebsd* ]]; then
                LBT_LINK=$(readelf -d ${libdir}/${nm}.so | grep lib${BLAS_NAME} | sed -e 's/.*\[\(.*\)\].*/\1/')
                patchelf --replace-needed ${LBT_LINK} lib${BLAS_NAME}.so ${libdir}/${nm}.so
            fi
        fi
    done
fi

# Delete the extra soversion libraries built. https://github.com/JuliaPackaging/Yggdrasil/issues/7
if [[ "${target}" == *-mingw* ]]; then
    rm -f ${libdir}/lib*.*.${dlext}
    rm -f ${libdir}/lib*.*.*.${dlext}
fi

install_license ../LICENSE.txt
"""
end
