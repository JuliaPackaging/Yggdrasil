using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "C/CUDA", "common.jl"))

name = "Libxc_GPU"
version = v"7.0.0"
include("../sources.jl")

# Bash recipe for building GPU version
# Notes:
#   - 3rd and 4th derivatives (KXC, LXC) not built since gives a binary size of ~200MB
#   - For compilation on aarch64, the official x86_86 CUDA redist is downloaded, in order
#     to enable cross compilation with NVCC
script = raw"""
cd $WORKSPACE/srcdir/libxc-*/

# CMake looks for CUDA libraries in lib64
ln -s $prefix/cuda/lib $prefix/cuda/lib64

# Necessary operations to cross compile CUDA from x86_64 to aarch64
if [[ "${target}" == aarch64-linux-* ]]; then

   # Add /usr/lib/csl-musl-x86_64 to LD_LIBRARY_PATH to be able to use host nvcc
   export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
   
   # Make sure we use host CUDA executable by copying from the x86_64 CUDA redist
   NVCC_DIR=(/workspace/srcdir/cuda_nvcc-*-archive)
   rm -rf ${prefix}/cuda/bin
   cp -r ${NVCC_DIR}/bin ${prefix}/cuda/bin

   # From CUDA v13 on, nvvm is not distributed in the NVCC redist anymore
   if [[ "${bb_full_target}" == *cuda+13* ]]; then
       NVVM_DIR=(/workspace/srcdir/libnvvm-*-archive)
   else
       NVVM_DIR=${NVCC_DIR}
   fi
   rm -rf ${prefix}/cuda/nvvm
   cp -r ${NVVM_DIR}/nvvm ${prefix}/cuda/nvvm
fi

mkdir libxc_build
cd libxc_build

cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CUDA_COMPILER=${prefix}/cuda/bin/nvcc \
      -DCMAKE_CUDA_FLAGS="--cudart shared" `#Use shared CUDA runtime` \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_TESTING=OFF \
      -DENABLE_CUDA=ON \
      -DENABLE_XHOST=OFF \
      -DENABLE_FORTRAN=ON \
      -DDISABLE_KXC=ON ..
cmake --build . --parallel $nproc
cmake --install .

unlink $prefix/cuda/lib64

install_license ../COPYING

if [[ "${target}" == aarch64-linux-* ]]; then
   # ensure products directory is clean
   rm -rf ${prefix}/cuda
fi
"""

# Override the default platforms
platforms = CUDA.supported_platforms(; min_version=v"11.8")
platforms = expand_gfortran_versions(platforms)
platforms = remove_unsupported_platforms(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libxc", :libxc)
    LibraryProduct("libxcf03", :libxcf03)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build Libxc for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform)
    cuda_ver = platform["cuda"]

    # Download the CUDA redist for the host x64_64 architecture
    platform_sources = BinaryBuilder.AbstractSource[sources...]
    if arch(platform) == "aarch64"

        # From CUDA v13 on, nvvm is not shipped with nvcc anymore
        components = ["cuda_nvcc"]
        if VersionNumber(cuda_ver) >= v"13.0"
           push!(components, "libnvvm")
        end
        x86_platform = deepcopy(platform)
        x86_platform["arch"] = "x86_64"
        append!(platform_sources, get_sources("cuda", components; platform=x86_platform,
                                              version=CUDA.full_version(VersionNumber(cuda_ver))))
    end

    build_tarballs(ARGS, name, version, platform_sources, script, [platform], products, [dependencies; cuda_deps];
                   lazy_artifacts=true,
                   julia_compat="1.6",
                   augment_platform_block=CUDA.augment,
                   preferred_gcc_version=v"8")
end
