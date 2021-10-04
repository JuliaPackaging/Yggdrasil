# CUDA forward compatibility package as taken from the datacenter driver
#
# - https://docs.nvidia.com/deploy/cuda-compatibility/index.html#forward-compatibility-title
# - https://docs.nvidia.com/datacenter/tesla/index.html
# - https://www.nvidia.com/Download/index.aspx

using BinaryBuilder, Pkg

include("../../../fancy_toys.jl")

name = "CUDA_compat"
version = v"0.0.1"

dependencies = []

script = raw"""
sh installer.run -x
cd NVIDIA-*
find .

install_license LICENSE

mkdir -p ${libdir}

ln -s libcuda.so.* libcuda.so
mv libcuda.so* ${libdir}

ln -s libnvidia-ptxjitcompiler.so.* libnvidia-ptxjitcompiler.so
mv libnvidia-ptxjitcompiler.so* ${libdir}
"""

products = [
    LibraryProduct("libcuda", :libcuda),
    LibraryProduct("libnvidia-ptxjitcompiler", :libnvidia_ptxjitcompiler),
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

cuda_versions = [v"11.4"]
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    include("build_$(cuda_tag).jl")
end
