using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

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
   export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib:/lib64:/lib:/workspace/x86_64-linux-musl-cxx11/destdir/lib:/workspace/x86_64-linux-musl-cxx11/destdir/lib64:/opt/x86_64-linux-musl/x86_64-linux-musl/lib64:/opt/x86_64-linux-musl/x86_64-linux-musl/lib:/opt/${target}/${target}/lib64:/opt/${target}/${target}/lib:/workspace/destdir/lib64"
   
   # Make sure we use host CUDA executable by copying from the x86_64 CUDA redist
   NVCC_DIR=(/workspace/srcdir/cuda_nvcc-*-archive)
   rm -rf ${prefix}/cuda/bin
   cp -r ${NVCC_DIR}/bin ${prefix}/cuda/bin
   
   rm -rf ${prefix}/cuda/nvvm/bin
   cp -r ${NVCC_DIR}/nvvm/bin ${prefix}/cuda/nvvm/bin
fi

mkdir libxc_build
cd libxc_build

cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CUDA_COMPILER=${prefix}/cuda/bin/nvcc \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_TESTING=OFF \
      -DENABLE_CUDA=ON \
      -DENABLE_XHOST=OFF \
      -DENABLE_FORTRAN=OFF \
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

# The products that we will ensure are always built
products = [
    LibraryProduct("libxc", :libxc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build Libxc for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform; static_sdk=true)
    cuda_ver = platform["cuda"]

    # Download the CUDA redist for the host x64_64 architecture
    platform_sources = BinaryBuilder.AbstractSource[sources...]
    if arch(platform) == "aarch64"
        if cuda_ver == "11.8"
            continue
        elseif cuda_ver == "12.0"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.0.1.json
            push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.0.140-archive.tar.xz", 
                                "906b894dffd853acefe6ab3d2a6cd74a0aa99b34bb8ca1e848174bddf55bfa3b"),
                 )
        elseif cuda_ver == "12.1"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.1.1.json
            push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.1.105-archive.tar.xz", 
                                "0b85f7eee17788abbd170b0b493c74ce2e9fd5a9604461b99c2c378165e1083b"),
                 )
        elseif cuda_ver == "12.2"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.2.1.json
            push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.2.128-archive.tar.xz", 
                                "018086c6bce5868451b0d30c74fd78826e15a2af0e9d891c1843bc2c3884bdec"),
                 )
        elseif cuda_ver == "12.3"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.3.1.json
            push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.3.103-archive.tar.xz",
                                "ae86efce6a69e99c55def1203157aee4bf71d6e5f8423c2a8d69a0e97036e9db"),
                 )
        elseif cuda_ver == "12.4"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.4.1.json
            push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.4.131-archive.tar.xz",
                                "7ffba1ada0e4b8c17e451ac7a60d386aa2642ecd08d71202a0b100c98bd74681"),
                 )
        elseif cuda_ver == "12.5"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.5.1.json
            push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.5.82-archive.tar.xz",
                                "ded05fe3c8d075c6c1bf892005d3c50bde3eceaa049b879fcdff6158e068e3be"),
                 )
        elseif cuda_ver == "12.6"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.6.1.json
            push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.6.68-archive.tar.xz",
                                "b672d0c36a27ea4577536725713064c9daa5d7378ac85877bc847ca9a46b2645"),
                 )
        elseif cuda_ver == "12.8"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.8.1.json
            push!(platform_sources,
                  ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.8.93-archive.tar.xz",
                                "9961b3484b6b71314063709a4f9529654f96782ad39e72bf1e00f070db8210d3"),
                 )
        end
    end

    build_tarballs(ARGS, name, version, platform_sources, script, [platform], products, [dependencies; cuda_deps];
                   lazy_artifacts=true,
                   julia_compat="1.8",
                   augment_platform_block=CUDA.augment,
                   preferred_gcc_version=v"8")
end
