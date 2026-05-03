# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, BinaryBuilderBase

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "HeFFTe"
version = v"2.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/icl-utk-edu/heffte.git", "6e16996e5a3eb65c60fd62fd4d93c4b2df833033")
]

# Bash recipe for building across all platforms
# Note: HeFFTe requires MPI unconditionally (find_package(MPI REQUIRED))
script = raw"""
cd $WORKSPACE/srcdir/heffte

cmake_extra_args=""

# Detect CUDA
if [[ "${bb_full_target}" == *cuda\+none* || "${bb_full_target}" != *cuda* ]]; then
    CUDA_OPTION="OFF"
else
    CUDA_OPTION="ON"
    export PATH=$PATH:$prefix/cuda/bin/
    export CUDA_PATH=$prefix/cuda/
    ln -s $prefix/cuda/lib/stubs/libcuda.so $prefix/cuda/lib/libcuda.so
    ln -s $prefix/cuda/lib $prefix/cuda/lib64
    cmake_extra_args="\
        -DCUDA_TOOLKIT_ROOT_DIR=$prefix/cuda/ \
        -DCMAKE_CUDA_HOST_COMPILER=$CXX \
        -DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined \
    "
fi

cmake -B build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_FIND_ROOT_PATH="${prefix}/lib/mpich;${prefix}" \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DMPI_C_COMPILER=$bindir/mpicc \
    -DMPI_CXX_COMPILER=$bindir/mpicxx \
    -DHeffte_ENABLE_FFTW=ON \
    -DHeffte_ENABLE_CUDA=${CUDA_OPTION} \
    -DHeffte_ENABLE_TESTING=OFF \
    ${cmake_extra_args}

cmake --build build -j${nproc}
cmake --install build

# Clean up CUDA stubs
if [[ "${bb_full_target}" != *cuda\+none* && "${bb_full_target}" == *cuda* ]]; then
    unlink $prefix/cuda/lib/libcuda.so
fi
"""

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

# HeFFTe requires MPI, so all platforms must have MPI.
# Restrict to HPC-relevant Linux architectures.
const hpc_archs = ("x86_64", "aarch64", "powerpc64le")
platforms = filter(p -> Sys.islinux(p) && arch(p) in hpc_archs, supported_platforms())
platforms = expand_cxxstring_abis(platforms)

# Use default MPI compat ranges from platforms/mpi.jl
mpi_platforms, mpi_dependencies = MPI.augment_platforms(platforms)

# CUDA+MPI platforms (x86_64 only)
cuda_platforms = expand_cxxstring_abis(CUDA.supported_platforms(min_version=v"11.0"))
filter!(p -> arch(p) == "x86_64", cuda_platforms)
cudampi_platforms, cudampi_dependencies = MPI.augment_platforms(cuda_platforms)

all_platforms = [mpi_platforms; cudampi_platforms]
for platform in all_platforms
    if CUDA.is_supported(platform) && !haskey(platform, "cuda")
        platform["cuda"] = "none"
    end
end


# The products that we will ensure are always built
products = [
    LibraryProduct("libheffte", :libheffte)
]

# Dependencies that must be installed before this package can be built
dependencies = AbstractDependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
]

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
for platform in all_platforms
    should_build_platform(triplet(platform)) || continue
    _dependencies = copy(dependencies)
    if haskey(platform, "cuda") && platform["cuda"] != "none"
        append!(_dependencies, cudampi_dependencies)
        append!(_dependencies, CUDA.required_dependencies(platform, static_sdk=true))
        push!(_dependencies, Dependency(PackageSpec(name="CUDA_Driver_jll")))
    else
        append!(_dependencies, mpi_dependencies)
    end
    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, _dependencies;
                   augment_platform_block,
                   julia_compat="1.6",
                   preferred_gcc_version=v"9",
                   lazy_artifacts=true)
end
