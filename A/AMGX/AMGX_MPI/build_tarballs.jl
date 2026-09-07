using BinaryBuilder, Pkg, BinaryBuilderBase

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

# This is the distributed build of AMGX. It is a separate package rather than a
# variant of AMGX_jll because MPI support changes the ABI: it defines
# AMGX_WITH_MPI, links MPI::MPI_CXX, and exposes the distributed entry points.
# Users who do not need MPI should keep using AMGX_jll, which stays a single
# build per CUDA version instead of one per MPI ABI.
#
# The sources and patches are shared with ../build_tarballs.jl -- keep the two
# in step when updating AMGX.

name = "AMGX_MPI"
version = v"2.5.0"

sources = [
    GitSource("https://github.com/NVIDIA/AMGX.git",
              "cc1cebdbb32b14d33762d4ddabcb2e23c1669f47"),
    DirectorySource("../bundled")
]

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

    NVCC_DIR=(${WORKSPACE}/srcdir/cuda_nvcc-linux-x86_64-*-archive)
    NVVM_DIR=(${WORKSPACE}/srcdir/libnvvm-linux-x86_64-*-archive)

    rm -rf ${prefix}/cuda/bin
    cp -a "${NVCC_DIR[0]}/bin" "${prefix}/cuda/bin"

    if [[ -d "${NVCC_DIR[0]}/nvvm/bin" ]]; then
        rm -rf ${prefix}/cuda/nvvm/bin
        cp -a "${NVCC_DIR[0]}/nvvm/bin" "${prefix}/cuda/nvvm/bin"
        [[ -d "${NVCC_DIR[0]}/nvvm/lib64" ]] && { rm -rf ${prefix}/cuda/nvvm/lib64; cp -a "${NVCC_DIR[0]}/nvvm/lib64" "${prefix}/cuda/nvvm/lib64"; }
    elif [[ -d "${NVVM_DIR[0]}/nvvm/bin" ]]; then
        rm -rf ${prefix}/cuda/nvvm/bin
        cp -a "${NVVM_DIR[0]}/nvvm/bin" "${prefix}/cuda/nvvm/bin"
        [[ -d "${NVVM_DIR[0]}/nvvm/lib64" ]] && { rm -rf ${prefix}/cuda/nvvm/lib64; cp -a "${NVVM_DIR[0]}/nvvm/lib64" "${prefix}/cuda/nvvm/lib64"; }
    else
        echo "ERROR: no host x86_64 nvvm found; cannot cross-compile CUDA device code"
        exit 1
    fi

    export NVCC_PREPEND_FLAGS="-ccbin=${CXX}"
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

mkdir build
cd build
# AMGX enables MPI whenever `find_package(MPI)` succeeds, defining AMGX_WITH_MPI
# and linking MPI::MPI_CXX. Point it at the MPI from the JLL explicitly so it
# cannot pick up anything else.
cmake -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CUDA_COMPILER=$prefix/cuda/bin/nvcc \
      -DCMAKE_CUDA_FLAGS="-L${prefix}/cuda/lib" \
      -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}" \
      -DMPI_C_COMPILER=${bindir}/mpicc \
      -DMPI_CXX_COMPILER=${bindir}/mpicxx \
      -Wno-dev \
      .. > cmake.log 2>&1 || { cat cmake.log; exit 1; }
cat cmake.log

# AMGX prints this once `find_package(MPI)` has succeeded and AMGX_WITH_MPI is
# set. Fail loudly rather than silently shipping a non-MPI build under this name.
grep -q "This is a MPI build:TRUE" cmake.log || \
  { echo "ERROR: MPI was not detected; refusing to build AMGX_MPI without MPI"; exit 1; }

make -j${nproc} install

# clean-up
## unneeded static libraries
rm ${libdir}/*.a

## the host x86_64 nvcc we swapped in must not end up in an aarch64 artifact
if [[ "${target}" == aarch64-linux-* ]]; then
    rm -rf ${prefix}/cuda
fi
"""

# AMGX 2.5 requires CUDA 12.0 or later, and nvcc only cross-compiles to Linux.
platforms = CUDA.supported_platforms(; min_version=v"12")
filter!(p -> arch(p) in ("x86_64", "aarch64"), platforms)

platforms, mpi_dependencies = MPI.augment_platforms(platforms)

# Only MPItrampoline to begin with. Expanding over every ABI would multiply an
# already large CUDA matrix by four (136 builds), and MPItrampoline is the one
# that can be retargeted at another MPI at runtime through MPIPreferences, so it
# is the most useful single choice. The other ABIs can be added later if there
# is demand; `mpi_dependencies` is already platform-constrained, so dropping
# platforms here is enough.
filter!(p -> p["mpi"] == "mpitrampoline", platforms)

# Selection has to consider both the CUDA toolkit and the MPI ABI.
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
    LibraryProduct("libamgxsh", :libamgxsh),
]

# AMGX 2.5 dropped support for everything below Volta, and only knows about the
# architectures listed in `CUDA_ALLOW_ARCH` in its CMakeLists.txt.
const amgx_archs = ["70", "75", "80", "86", "89", "90", "100", "120"]

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the
# shared libraries. (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    dependencies = AbstractDependency[mpi_dependencies...]
    append!(dependencies, CUDA.required_dependencies(platform; static_sdk=true))

    sources_platform = BinaryBuilder.AbstractSource[sources...]
    if arch(platform) == "aarch64"
        cuda_version = VersionNumber(platform["cuda"])
        components = ["cuda_nvcc"]
        cuda_version >= v"13" && push!(components, "libnvvm")
        x86_platform = deepcopy(platform)
        x86_platform["arch"] = "x86_64"
        append!(sources_platform, get_sources("cuda", components;
                                              version=CUDA.full_version(cuda_version),
                                              platform=x86_platform))
    end

    archs = filter(in(amgx_archs), CUDA.cuda_gpu_archs(platform))
    platform_script = "CUDA_ARCHS=\"$(join(archs, ";"))\"\n" * script

    build_tarballs(ARGS, name, version, sources_platform, platform_script, [platform],
                   products, dependencies; lazy_artifacts=true,
                   julia_compat="1.10", augment_platform_block,
                   dont_dlopen=true, preferred_gcc_version=v"12")
end
