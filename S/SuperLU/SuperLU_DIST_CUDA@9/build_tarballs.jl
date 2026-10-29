# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, BinaryBuilderBase
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

# CUDA build of ../SuperLU_DIST@9 -- keep the two in step when updating SuperLU_DIST.
name = "SuperLU_DIST_CUDA"
version = v"9.3.1"

sources = [
    GitSource("https://github.com/xiaoyeli/superlu_dist.git", "9f7c8196d8f692cbfc59d81b61a74ceb4b37789b"; tag="v$(version)"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/superlu_dist*
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

# nvcc writes to /tmp, which is a small tmpfs in the sandbox.
export TMPDIR=${WORKSPACE}/tmpdir
mkdir -v ${TMPDIR}

# CUDA 13's cuBLASLt and cuSOLVER need a newer glibc than the sysroot's, which
# only breaks linking the pdtest executables.
EXE_LDFLAGS="-Wl,--allow-shlib-undefined"

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

    cmake -B build-${INT} \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_STATIC_LIBS=OFF \
        -DTPL_ENABLE_INTERNAL_BLASLIB=OFF \
        -Denable_tests=ON \
        -Denable_doc=OFF \
        -Denable_single=ON \
        -Denable_double=ON \
        -Denable_complex16=ON \
        -DTPL_BLAS_LIBRARIES="${libdir}/libblastrampoline.${dlext}" \
        -DTPL_ENABLE_LAPACKLIB=ON \
        -DTPL_LAPACK_LIBRARIES="${libdir}/libblastrampoline.${dlext}" \
        -DTPL_ENABLE_PARMETISLIB=ON \
        -DTPL_PARMETIS_INCLUDE_DIRS="${includedir}" \
        -DTPL_PARMETIS_LIBRARIES="${PARMETIS_PATH};${METIS_PATH}" \
        -DTPL_ENABLE_CUDALIB=ON \
        -DCMAKE_CUDA_COMPILER=${prefix}/cuda/bin/nvcc \
        -DCMAKE_CUDA_FLAGS="-L${prefix}/cuda/lib" \
        -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}" \
        -DCMAKE_EXE_LINKER_FLAGS="${EXE_LDFLAGS}" \
        -DCMAKE_C_FLAGS="-std=c99 -Wno-implicit-function-declaration -Wno-incompatible-pointer-types" \
        -DXSDK_INDEX_SIZE=${INT} \
        -DXSDK_ENABLE_Fortran=OFF \
        -DSUPERLU_OUTPUT_NAME="superlu_dist_Int${INT}" \
        -Denable_examples=OFF \
        -Denable_python=OFF
    cmake --build build-${INT} --parallel ${nproc}
    cmake --install build-${INT}

    install -Dvm 755 build-${INT}/TEST/pdtest "${bindir}/pdtest_${INT}"
    install -vm 644 EXAMPLE/g20.rua "${includedir}"

    # Both widths install into ${includedir}, so the second build overwrites
    # the first's superlu_dist_config.h (XSDK_INDEX_SIZE). Keep a per-width
    # copy right after each install for consumers such as PETSc.
    mkdir -pv ${includedir}/superlu_dist_Int${INT}
    cp -v ${includedir}/superlu*.h* ${includedir}/superlu_dist_Int${INT}/
}
build_superlu_dist Int32
build_superlu_dist Int64
"""

# aarch64 would need the host x86_64 nvcc swapped in, as A/AMGX/AMGX_MPI does.
platforms = CUDA.supported_platforms(; min_version=v"12")
filter!(p -> arch(p) == "x86_64", platforms)

platforms, mpi_dependencies = MPI.augment_platforms(platforms)

# Only MPItrampoline, which MPIPreferences can retarget at any system MPI at
# runtime. Every ABI would multiply the CUDA matrix by four.
filter!(p -> p["mpi"] == "mpitrampoline", platforms)

augment_platform_block = """
    using Base.BinaryPlatforms

    module __CUDA
        $(CUDA.augment)
    end

    $(MPI.augment)

    function augment_platform!(platform::Platform)
        augment_mpi!(platform)
        __CUDA.augment_platform!(platform)
    end
"""

products = [
    ExecutableProduct("pdtest_32", :pdtest_32),
    ExecutableProduct("pdtest_64", :pdtest_64),

    LibraryProduct("libsuperlu_dist_Int32", :libsuperlu_dist_Int32),
    LibraryProduct("libsuperlu_dist_Int64", :libsuperlu_dist_Int64),
]

dependencies = AbstractDependency[
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"); compat="5.4.0"),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"); compat="0.3.32"),
    Dependency(PackageSpec(name="PARMETIS_jll", uuid="b247a4be-ddc1-5759-8008-7e02fe3dbdaa"); compat="4.0.9"),
    Dependency("METIS_jll"; compat="5.1.4"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); compat="1.0.5"),
]
append!(dependencies, mpi_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the
# shared libraries. (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    platform_dependencies = [dependencies; CUDA.required_dependencies(platform; static_sdk=true)]
    platform_script = "CUDA_ARCHS=\"$(join(CUDA.cuda_gpu_archs(platform), ";"))\"\n" * script

    build_tarballs(ARGS, name, version, sources, platform_script, [platform],
                   products, platform_dependencies; lazy_artifacts=true,
                   augment_platform_block, julia_compat="1.11",
                   dont_dlopen=true, preferred_gcc_version=v"8")
end
