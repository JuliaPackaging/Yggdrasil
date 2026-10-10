using BinaryBuilder, Pkg, BinaryBuilderBase

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# TODO: Ship nvToolsExt.h with NVTX_jll and use here instead of patching it out.
#       AMGX includes <nvtx3/nvToolsExt.h>, but CUDA_SDK_jll does not ship the
#       `cuda_nvtx` redistributable component, so NVTX ranges stay disabled.

name = "AMGX"
version = v"2.5.0"

# Collection of sources required to complete build
base_sources = [
    GitSource("https://github.com/NVIDIA/AMGX.git",
              "cc1cebdbb32b14d33762d4ddabcb2e23c1669f47"),
    DirectorySource("./bundled")
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
cmake -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CUDA_COMPILER=$prefix/cuda/bin/nvcc \
      -DCMAKE_CUDA_FLAGS="-L${prefix}/cuda/lib" \
      -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}" \
      -Wno-dev \
      ..

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
platforms = CUDA.supported_platforms(; min_version=v"12")
filter!(p -> arch(p) in ("x86_64", "aarch64"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libamgxsh", :libamgxsh),
]

# AMGX 2.5 dropped support for everything below Volta, and only knows about the
# architectures listed in `CUDA_ALLOW_ARCH` in its CMakeLists.txt. Without an
# explicit list it would only build for `90;100;120`, which excludes Ampere.
const amgx_archs = ["70", "75", "80", "86", "89", "90", "100", "120"]

# GCC 11 is the first version that defaults to -std=gnu++17. CUDA 13 ships
# CCCL 3 (Thrust, CUB, libcu++), which refuses to compile as anything older,
# and AMGX does not set the standard itself.
#
# Build for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    dependencies = CUDA.required_dependencies(platform; static_sdk=true)

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

    build_tarballs(ARGS, name, version, sources, platform_script, [platform],
                   products, dependencies; lazy_artifacts=true,
                   julia_compat="1.10", augment_platform_block=CUDA.augment,
                   dont_dlopen=true, preferred_gcc_version=v"12")
end
