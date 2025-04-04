# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "SuperLU_DIST_CUDA"
version = v"8.1.2"
superlu_dist_version = v"8.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xiaoyeli/superlu_dist.git", "58e4171dda309255b3b66b0923cd04124f4c0c01"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/superlu_dist*
# allow us to set the name of the shared lib.
sed -i -e 's!OUTPUT_NAME superlu_dist!OUTPUT_NAME "${SUPERLU_OUTPUT_NAME}"!g' SRC/CMakeLists.txt

if [[ "${target}" == *-mingw* ]]; then
    # This is required to ensure that MSMPI can be found by cmake
    export LDFLAGS="-L${libdir} -lmsmpi"
    PLATFLAGS="-DTPL_ENABLE_PARMETISLIB:BOOL=FALSE -DMPI_C_ADDITIONAL_INCLUDE_DIRS=${includedir}"
fi

## CUDA setup per Ian McInerney
# nvcc writes to /tmp, which is a small tmpfs in our sandbox.
# make it use the workspace instead
export TMPDIR=${WORKSPACE}/tmpdir
mkdir ${TMPDIR}
mkdir -p /usr/local
ln -s ${prefix}/cuda /usr/local/cuda
export PATH="/usr/local/cuda/bin:${PATH}"

BLAS="libopenblas"

build_superlu_dist()
{
    if [[ "${1}" == "Int64" ]]; then
        INT=64
        METIS_PATH="${libdir}/metis/metis_Int64_Real32/lib/libmetis_Int64_Real32.${dlext}"
        PARMETIS_PATH="${libdir}/libparmetis_Int64_Real32.${dlext}"
    else
        INT=32
        METIS_PATH="${libdir}/libmetis.${dlext}"
        PARMETIS_PATH="${libdir}/libparmetis.${dlext}"
    fi
    if [[ "${target}" != *-mingw* ]]; then
        PLATFLAGS="-DTPL_ENABLE_PARMETISLIB:BOOL=TRUE -DTPL_PARMETIS_INCLUDE_DIRS=${includedir} -DTPL_PARMETIS_LIBRARIES=${PARMETIS_PATH};${METIS_PATH}"
    fi

    mkdir build-${INT}
    pushd build-${INT}
    cmake \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_STATIC_LIBS=OFF \
        -DTPL_ENABLE_INTERNAL_BLASLIB=OFF \
        -Denable_tests=OFF \
        -Denable_doc=OFF \
        -Denable_single=ON \
        -Denable_double=ON \
        -Denable_complex16=ON \
        -DTPL_BLAS_LIBRARIES="${libdir}/${BLAS}.${dlext}" \
        ${PLATFLAGS} \
        -DCMAKE_C_FLAGS="-std=c99" \
        -DXSDK_INDEX_SIZE=${INT} \
        -DXSDK_ENABLE_Fortran=OFF \
        -DSUPERLU_OUTPUT_NAME="superlu_dist_Int${INT}" \
        -Denable_examples=OFF \
        -DTPL_ENABLE_CUDALIB=ON \
        ..
    make -j${nproc}
    make install
    popd
}
build_superlu_dist Int32
build_superlu_dist Int64
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    $(CUDA.augment)
    augment_platform!(platform::Platform) = (augment_mpi!(augment_platform!(platform))
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Excluding Windows due to use of `getline` function, which is non-standard and not provided by MinGW
# per Mose. Will return to it later and attempt to find a solution.
platforms = [
    Platform("x86_64", "linux"),
    # Platform("aarch64", "linux"),
    # Platform("powerpc64le", "linux")
]
platforms, mpi_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.2.1")
# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsuperlu_dist_Int32", :libsuperlu_dist_Int32, ["\$libdir/superlu_dist/Int32/lib", "\$libdir/superlu_dist/Int32/bin"]),
    LibraryProduct("libsuperlu_dist_Int64", :libsuperlu_dist_Int64, ["\$libdir/superlu_dist/Int64/lib", "\$libdir/superlu_dist/Int64/bin"])
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    Dependency(PackageSpec(name="PARMETIS_jll", uuid="b247a4be-ddc1-5759-8008-7e02fe3dbdaa"); platforms=filter(!Sys.iswindows, platforms), compat="4.0.6"),
    Dependency("METIS_jll"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

cuda_full_versions = Dict(
    v"10.2" => v"10.2.89",
    v"11.0" => v"11.0.3",
    v"11.1" => v"11.1.1",
    # v"12.0" => v"12.0.0",
)

cuda_archs = Dict(
    v"10.2" => "35;50;60;70",
    v"11.0" => "60;70;80",
    v"11.1" => "60;70;80",
    # v"12.0" => "60;70;80",
)

append!(dependencies, mpi_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
# Require GCC 8 to avoid `error: libgfortran.so.4: cannot open shared object file`
for cuda_version in [v"10.2", v"11.0"], platform in platforms
    augmented_platform = deepcopy(platform)
    augmented_platform["cuda"] = CUDA.platform(cuda_version)
    should_build_platform(triplet(augmented_platform)) || continue

    cuda_deps = [
        BuildDependency(PackageSpec(name="CUDA_full_jll",
                                    version=cuda_full_versions[cuda_version])),
        RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")),
    ]
    build_tarballs(ARGS, name, version, sources, script, [augmented_platform],
                   products, [dependencies; cuda_deps]; lazy_artifacts=true,
                   julia_compat="1.9", augment_platform_block,
                   skip_audit=true, dont_dlopen=true)
end