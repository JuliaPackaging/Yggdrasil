# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, BinaryBuilderBase

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "HeFFTe"
version = v"2.4.1"
ygg_version = v"2.4.3"  # compat changes need a new JLL version

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/icl-utk-edu/heffte.git", "6e16996e5a3eb65c60fd62fd4d93c4b2df833033";
              tag="v$(version)")
]

# Bash recipe for building across all platforms
# Note: HeFFTe requires MPI unconditionally (find_package(MPI REQUIRED))
script = raw"""
cd $WORKSPACE/srcdir/heffte

# The MPItrampoline compiler wrappers otherwise use the compilers MPItrampoline was built with.
export MPITRAMPOLINE_CC=${CC} MPITRAMPOLINE_CXX=${CXX} MPITRAMPOLINE_FC=${FC}

if [[ "${bb_full_target}" != *-cuda+[0-9]* ]]; then
    CMAKE_FLAGS=(-DHeffte_ENABLE_CUDA=OFF)
else
    # nvcc searches lib64; the SDK uses lib. Vendor libraries require newer glibc symbols.
    CMAKE_FLAGS=(
        -DHeffte_ENABLE_CUDA=ON
        -DCMAKE_CUDA_COMPILER=${prefix}/cuda/bin/nvcc
        -DCMAKE_CUDA_HOST_COMPILER=${CXX}
        -DCMAKE_CUDA_FLAGS="-L${prefix}/cuda/lib"
        -DCMAKE_EXE_LINKER_FLAGS="-Wl,--allow-shlib-undefined"
        -DCUDAToolkit_ROOT=${prefix}/cuda
        -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}"
    )
fi

cmake -B build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DMPI_HOME=${prefix} \
    -DHeffte_ENABLE_FFTW=ON \
    -DHeffte_ENABLE_TESTING=OFF \
    "${CMAKE_FLAGS[@]}"

cmake --build build -j${nproc}
cmake --install build
"""

augment_platform_block = CUDA.augment_with(MPI.augment, "augment_mpi!")

# HeFFTe requires MPI, so all platforms must have MPI.
# Linux and macOS, x86_64 and aarch64. CUDA stays on Linux x86_64.
const hpc_archs = ("x86_64", "aarch64")
platforms = filter(p -> (Sys.islinux(p) || Sys.isapple(p)) && arch(p) in hpc_archs, supported_platforms())
platforms = expand_cxxstring_abis(platforms)

# Use default MPI compat ranges from platforms/mpi.jl
mpi_platforms, mpi_dependencies = MPI.augment_platforms(platforms)

# CUDA+MPI platforms (x86_64 only). A cuda=12.0 or 13.0 artifact also matches newer
# toolkits of the same major, so the other minor versions aren't needed.
cuda_platforms = CUDA.supported_platforms(; min_version=v"12.0", max_version=v"13.0.999")
filter!(p -> Base.thisminor(VersionNumber(p["cuda"])) in (v"12.0", v"13.0"), cuda_platforms)
filter!(p -> arch(p) == "x86_64", cuda_platforms)
cuda_platforms = expand_cxxstring_abis(cuda_platforms)
cudampi_platforms, cudampi_dependencies = MPI.augment_platforms(cuda_platforms)
# Limit the number of CUDA builds; MPItrampoline stays because earlier versions shipped it.
filter!(p -> p["mpi"] in ("mpiabi", "mpich", "mpitrampoline"), cudampi_platforms)

all_platforms = [mpi_platforms; cudampi_platforms]
for platform in all_platforms
    if CUDA.is_supported(platform) && !haskey(platform, "cuda")
        platform["cuda"] = "none"
    end
end
cuda_dependencies = CUDA.required_dependencies(all_platforms; static_sdk=true)


# The products that we will ensure are always built
products = [
    LibraryProduct("libheffte", :libheffte)
]

# Dependencies that must be installed before this package can be built
dependencies = AbstractDependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); compat="1.0.5"),
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"); compat="3.3.10"),
]

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
for platform in all_platforms
    should_build_platform(triplet(platform)) || continue
    _dependencies = [dependencies; cuda_dependencies]
    _script = script
    if haskey(platform, "cuda") && platform["cuda"] != "none"
        append!(_dependencies, cudampi_dependencies)
        _script = "CUDA_ARCHS=\"$(CUDA.cuda_gpu_archs_cmake(platform))\"\n" * script
    else
        append!(_dependencies, mpi_dependencies)
    end
    build_tarballs(ARGS, name, ygg_version, sources, _script, [platform],
                   products, _dependencies;
                   augment_platform_block,
                   julia_compat="1.10",  # CUDA_Runtime_jll requires it
                   preferred_gcc_version=v"9",
                   lazy_artifacts=true,
                   # The build host may lack the CUDA libraries the CUDA builds link.
                   dont_dlopen=true)
end
