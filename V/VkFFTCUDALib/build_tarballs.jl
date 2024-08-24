using BinaryBuilder, Pkg
using BinaryBuilderBase
include(joinpath(@__DIR__, "..", "..", "fancy_toys.jl"))
include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "VkFFTCUDALib"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
		   GitSource("https://github.com/PaulVirally/VkFFTCUDALib.git", "9c8cf2eae261b363e185e5043599ca2726f5aafd")
		  ]

script = raw"""
cd $WORKSPACE/srcdir/VkFFTCUDALib
git submodule update --init

export CUDA_PATH="$prefix/cuda"
ln -s $prefix/cuda/lib $prefix/cuda/lib64

mkdir build && cd build
cmake .. \
-DCMAKE_PREFIX_PATH="${prefix}" \
-DCMAKE_INSTALL_PREFIX="${prefix}" \
-DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}" \
-DCUDA_TOOLKIT_ROOT_DIR="${prefix}/cuda" \
-DCMAKE_CUDA_COMPILER="${prefix}/cuda/bin/nvcc"
cmake --build . --parallel $nproc
cmake --install .

unlink $prefix/cuda/lib64

install_license ../LICENSE
"""

# Build for CUDA >= 11.0
platforms = expand_cxxstring_abis(CUDA.supported_platforms(min_version=v"11.0"))
# Cmake toolchain breaks on aarch64, so only x86_64 for now
# filter!(p -> arch(p)=="x86_64", platforms)

# The products that we will ensure are always built
products = [LibraryProduct("libVkFFTCUDA", :libVkFFTCUDA)]

# We need cmake >= 3.18 to build with CUDA
dependencies = [HostBuildDependency(PackageSpec(; name="CMake_jll", version=v"3.28.1"))]

for platform in platforms
	should_build_platform(triplet(platform)) || continue

	# We need the static sdk
	cuda_deps = CUDA.required_dependencies(platform; static_sdk=true)

	# Build for all major archs supported by SDK
	# See https://en.wikipedia.org/wiki/CUDA
	if VersionNumber(platform["cuda"]) < v"11.8"
		cuda_archs = "50;60;70;80"
	else
		cuda_archs = "50;60;70;80;90"
	end
	arch_line = "export CUDA_ARCHS=\"$cuda_archs\"\n"
	platform_script = arch_line * script

	build_tarballs(ARGS, name, version, sources, platform_script, [platform],
				   products, [dependencies; cuda_deps];
				   preferred_gcc_version=v"11",
				   julia_compat="1.7",
				   augment_platform_block=CUDA.augment
				  )
end
