# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "PaRSEC"
version = v"4.0.2411"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ICLDisco/parsec.git",
              "cdb2e7f5148b503e381eab110b77d9575540cbb9"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/parsec

# Make parsec-ptgpp import optional when cross-compiling (we only need libparsec).
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0002-fix-cmake-crosscompile-optional-ptgpp.patch

# Fix parsec_param_enable_mpi_overtake declared only under #if defined() but
# used in the #else branch too.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-fix-mpi-overtake-undeclared.patch

# Fix cudaDeviceProp fields removed in CUDA 13.0 (clockRate, computeMode,
# memoryClockRate). Guard with CUDART_VERSION < 13000.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0003-fix-cuda13-removed-devprop-fields.patch

# Detect the MPI implementation to give cmake's FindMPI a reliable hint.
# cmake cannot run the mpicc wrapper during cross-compilation, so we pass
# the full library path directly. All supported MPI JLLs are MPI 3.0+.
MPI_LIBS="mpi"
if grep -q MPItrampoline ${includedir}/mpi.h 2>/dev/null; then
    MPI_LIBS="mpitrampoline"
elif grep -q "MPI_ABI_VERSION" ${includedir}/mpi.h 2>/dev/null && [[ -f ${libdir}/libmpi_abi.${dlext} ]]; then
    MPI_LIBS="mpi_abi"
elif [[ "${target}" == *-mingw* ]]; then
    MPI_LIBS="msmpi"
fi
MPI_LIB_FILE="${libdir}/lib${MPI_LIBS}.${dlext}"

# Configure GPU flags based on whether a CUDA SDK is present.
# `bb_full_target` contains `cuda+<version>` for CUDA platforms and `cuda+none`
# (or no cuda tag) for CPU-only platforms.
if [[ "${bb_full_target}" == *cuda\+[0-9]* ]]; then
    export CUDA_HOME="${prefix}/cuda"
    # Some CUDA SDK versions put libs in lib/, others expect lib64/.
    ln -sf "${CUDA_HOME}/lib" "${CUDA_HOME}/lib64" 2>/dev/null || true
    export CUDACXX="${CUDA_HOME}/bin/nvcc"
    export PATH="${CUDA_HOME}/bin:${PATH}"
    # Help the linker find libcudart during CMake's compiler-ID test.
    export LDFLAGS="${LDFLAGS-} -L${CUDA_HOME}/lib"
    GPU_FLAGS=(
        -DPARSEC_GPU_WITH_CUDA=ON
        -DPARSEC_GPU_WITH_HIP=OFF
        -DPARSEC_GPU_WITH_LEVEL_ZERO=OFF
        -DPARSEC_GPU_WITH_OPENCL=OFF
        -DCUDAToolkit_ROOT="${CUDA_HOME}"
        # Pre-set the CUDA compiler so check_language(CUDA) finds it even when
        # CMAKE_CROSSCOMPILING=ON suppresses the normal compiler search.
        -DCMAKE_CUDA_COMPILER="${CUDA_HOME}/bin/nvcc"
        -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}"
        # Link against shared cudart (provided at runtime by CUDA_Runtime_jll).
        -DCMAKE_CUDA_FLAGS="-cudart shared"
    )
else
    GPU_FLAGS=(
        -DPARSEC_GPU_WITH_CUDA=OFF
        -DPARSEC_GPU_WITH_HIP=OFF
        -DPARSEC_GPU_WITH_LEVEL_ZERO=OFF
        -DPARSEC_GPU_WITH_OPENCL=OFF
    )
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DPARSEC_DIST_WITH_MPI=ON \
    -DPARSEC_DEBUG=OFF \
    -DPARSEC_PROF_TRACE=OFF \
    -DPARSEC_PROF_PINS=OFF \
    -DBUILD_TOOLS=OFF \
    -DSUPPORT_FORTRAN=OFF \
    -DBUILD_TESTING=OFF \
    -DMPI_C_LIBRARIES="${MPI_LIB_FILE}" \
    -DMPI_CXX_LIBRARIES="${MPI_LIB_FILE}" \
    -DMPI_C_INCLUDE_PATH="${prefix}/include" \
    -DMPI_C_INCLUDE_DIRS="${prefix}/include" \
    -DMPI_CXX_INCLUDE_DIRS="${prefix}/include" \
    -DPARSEC_HAVE_MPI_20=TRUE \
    -DPARSEC_HAVE_MPI_30=TRUE \
    -DPARSEC_HAVE_MPI_OVERTAKE=TRUE \
    -DHWLOC_ROOT=${prefix} \
    "${GPU_FLAGS[@]}"

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE.txt
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

# CPU platforms: all non-Windows platforms.
cpu_platforms = filter(p -> !Sys.iswindows(p), supported_platforms())

# CUDA platforms: x86_64-linux only. nvcc is an x86_64 host binary, so it can
# only run natively on x86_64 build hosts. aarch64 cross-compilation requires
# copying the x86_64 nvcc into the sysroot (see NCCL recipe); skip for now.
cuda_platforms = CUDA.supported_platforms(; min_version=v"11.8")
filter!(p -> arch(p) == "x86_64", cuda_platforms)

# Augment CPU and CUDA base platforms independently with MPI variants, then
# combine. Calling augment_platforms on separate sets lets MPI filter correctly
# (e.g. mpitrampoline is excluded from musl targets).
mpi_cpu_platforms, mpi_cpu_deps   = MPI.augment_platforms(cpu_platforms)
mpi_cuda_platforms, mpi_cuda_deps = MPI.augment_platforms(cuda_platforms)

all_platforms = [mpi_cpu_platforms; mpi_cuda_platforms]

# For CPU platforms that could in principle support CUDA (x86_64/aarch64/ppc64le
# Linux), tag them `cuda=none` so the augment block can distinguish at runtime
# between "no GPU driver" and "GPU not applicable".
for p in all_platforms
    if CUDA.is_supported(p) && !haskey(p, "cuda")
        p["cuda"] = "none"
    end
end

# The products that we will ensure are always built
products = [
    LibraryProduct("libparsec", :libparsec),
]

# Base dependencies shared by all platform variants
base_dependencies = BinaryBuilder.AbstractDependency[
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

for platform in all_platforms
    should_build_platform(triplet(platform)) || continue

    deps = copy(base_dependencies)
    cuda_ver = get(tags(platform), "cuda", "none")

    if cuda_ver != "none"
        # CUDA+MPI variant: add CUDA SDK (build-time) + runtime dependency.
        append!(deps, CUDA.required_dependencies(platform))
        append!(deps, mpi_cuda_deps)

        # Select GPU architectures appropriate for this CUDA version.
        cv = VersionNumber(cuda_ver)
        archs = if cv >= v"13"
            "75;80;90;100;120"
        elseif cv >= v"12"
            "60;70;80;90"
        else  # 11.x
            "60;70;80;86"
        end
        platform_script = "export CUDA_ARCHS=\"$archs\"\n" * script
    else
        append!(deps, mpi_cpu_deps)
        platform_script = script
    end

    build_tarballs(ARGS, name, version, sources, platform_script, [platform],
                   products, deps;
                   augment_platform_block,
                   julia_compat="1.6",
                   preferred_gcc_version=v"9",
                   lazy_artifacts=true)
end
