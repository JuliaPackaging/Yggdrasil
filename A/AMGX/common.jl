using BinaryBuilder, Pkg, BinaryBuilderBase

const YGGDRASIL_DIR = joinpath(@__DIR__, "..", "..")
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# TODO: Ship nvToolsExt.h with NVTX_jll and use here instead of patching it out.
#       AMGX includes <nvtx3/nvToolsExt.h>, but CUDA_SDK_jll does not ship the
#       `cuda_nvtx` redistributable component, so NVTX ranges stay disabled.

version = v"2.5.0"

# Collection of sources required to complete build
base_sources = [
    GitSource("https://github.com/NVIDIA/AMGX.git",
              "cc1cebdbb32b14d33762d4ddabcb2e23c1669f47"; tag="v$(version)"),
    DirectorySource("../bundled")
]

# Bash recipe for building across all platforms
script = raw"""
# nvcc writes to /tmp, which is a small tmpfs in our sandbox.
# make it use the workspace instead
export TMPDIR=${WORKSPACE}/tmpdir
mkdir ${TMPDIR}

# nvcc is not a cross compiler, but it does run on the build host and can be
# pointed at a cross C++ compiler. The CUDA SDK we get is the target's, so for
# aarch64 we swap in the host x86_64 nvcc (and nvvm, split into its own redist
# from CUDA 13) and tell it to use the cross compiler for host code.
if [[ "${target}" == aarch64-linux-* ]]; then
    export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
    export NVCC_PREPEND_FLAGS="-ccbin=${CXX}"
    rm -rfv ${prefix}/cuda/bin ${prefix}/cuda/nvvm/bin ${prefix}/cuda/nvvm/lib64
    cp -a ${WORKSPACE}/srcdir/cuda_nvcc-linux-x86_64-*-archive/bin ${prefix}/cuda/bin
    cp -a ${WORKSPACE}/srcdir/*-linux-x86_64-*-archive/nvvm/{bin,lib64} ${prefix}/cuda/nvvm/
fi

cd ${WORKSPACE}/srcdir/AMGX*

# Apply all our patches
if [ -d $WORKSPACE/srcdir/patches ]; then
for f in $WORKSPACE/srcdir/patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

install_license LICENSES/BSD-3-Clause.txt

# AMGX enables MPI whenever `find_package(MPI)` succeeds, defining AMGX_WITH_MPI
# and linking MPI::MPI_CXX. Point it at the MPI from the JLL explicitly so it
# cannot pick up anything else.
mpi_args=()
if [[ ${bb_full_target} == *mpi* ]]; then
    export MPITRAMPOLINE_CC=${CC} MPITRAMPOLINE_CXX=${CXX}
    mpi_args=(-DMPI_C_COMPILER=${bindir}/mpicc -DMPI_CXX_COMPILER=${bindir}/mpicxx)
fi

mkdir build
cd build
cmake -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CUDA_COMPILER=$prefix/cuda/bin/nvcc \
      -DCMAKE_CUDA_FLAGS="-L${prefix}/cuda/lib" \
      -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}" \
      "${mpi_args[@]}" \
      -Wno-dev \
      .. > cmake.log 2>&1 || { cat cmake.log; exit 1; }
cat cmake.log

# AMGX prints this once `find_package(MPI)` has succeeded and AMGX_WITH_MPI is
# set. Fail loudly rather than silently shipping a non-MPI build under this name.
if [[ ${bb_full_target} == *mpi* ]]; then
    grep -q "This is a MPI build:TRUE" cmake.log || \
      { echo "ERROR: MPI was not detected; refusing to build AMGX_MPI without MPI"; exit 1; }
fi

make -j${nproc} install

# clean-up
## unneeded static libraries
rm ${libdir}/*.a

## the host x86_64 nvcc we swapped in must not end up in an aarch64 artifact
if [[ "${target}" == aarch64-linux-* ]]; then
    rm -rf ${prefix}/cuda
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
#
# AMGX 2.5 requires CUDA 12.0 or later (`find_package(CUDAToolkit 12.0 REQUIRED)`).
# An artifact also matches newer toolkits of its major, so build each major's oldest.
platforms = [
    CUDA.supported_platforms(; min_version=v"12", max_version=v"12.0.999");
    CUDA.supported_platforms(; min_version=v"13", max_version=v"13.0.999")
]

# The products that we will ensure are always built.
# libamgxsh links libcuda directly, so the JLL must not load it without a driver.
products = [
    LibraryProduct("libamgxsh", :libamgxsh; dont_dlopen=true),
]

# AMGX 2.5 dropped support for everything below Volta, and only knows about the
# architectures listed in `CUDA_ALLOW_ARCH` in its CMakeLists.txt. Without an
# explicit list it would only build for `90;100;120`, which excludes Ampere.
const amgx_archs = ["70", "75", "80", "86", "89", "90", "100", "120"]

# Build for all supported CUDA toolkits
function build_amgx(ARGS, name, platforms, extra_dependencies, augment_platform_block)
    for platform in platforms
        should_build_platform(triplet(platform)) || continue

        dependencies = AbstractDependency[extra_dependencies...]
        append!(dependencies, CUDA.required_dependencies(platform; static_sdk=true))

        # aarch64 additionally needs the host x86_64 nvcc to actually run the compile
        sources = BinaryBuilder.AbstractSource[base_sources...]
        if arch(platform) == "aarch64"
            cuda_version = VersionNumber(platform["cuda"])
            components = ["cuda_nvcc"]
            cuda_version >= v"13" && push!(components, "libnvvm")
            x86_platform = deepcopy(platform)
            x86_platform["arch"] = "x86_64"
            append!(sources, get_sources("cuda", components;
                                         version=CUDA.full_version(cuda_version),
                                         platform=x86_platform))
        end

        archs = filter(in(amgx_archs), CUDA.cuda_gpu_archs(platform))
        platform_script = "CUDA_ARCHS=\"$(join(archs, ";"))\"\n" * script

        # GCC 11 is the first version that defaults to -std=gnu++17. CUDA 13 ships
        # CCCL 3 (Thrust, CUB, libcu++), which refuses to compile as anything older,
        # and AMGX does not set the standard itself.
        build_tarballs(ARGS, name, version, sources, platform_script, [platform],
                       products, dependencies; lazy_artifacts=true,
                       julia_compat="1.10", augment_platform_block,
                       dont_dlopen=true, preferred_gcc_version=v"12")
    end
end
