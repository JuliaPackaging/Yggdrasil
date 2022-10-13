# CUDA forward compatibility driver
#
# - https://docs.nvidia.com/deploy/cuda-compatibility/index.html#forward-compatibility-title
# - https://docs.nvidia.com/datacenter/tesla/index.html
# - https://www.nvidia.com/Download/index.aspx

using BinaryBuilder, Pkg

include("../../../fancy_toys.jl")

name = "CUDA_Driver"
version = v"11.8"

cuda_version = "$(version.major)-$(version.minor)"
driver_version = "520.61.05"
build = 1

sources_linux_x86 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-compat-$(cuda_version)-$(driver_version)-$(build).x86_64.rpm",
               "0dad75290f8aa33f6d1ae1e1fa9fcc501bc51a74746b5e9e12082866e322eabf", "compat.rpm")
]
sources_linux_ppc64le = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/ppc64le/cuda-compat-$(cuda_version)-$(driver_version)-$(build).ppc64le.rpm",
               "85dad0fddf28bf3cfcfe63c5dc77ce84acce2100f99afad43ae78143c0277484", "compat.rpm")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/sbsa/cuda-compat-$(cuda_version)-$(driver_version)-$(build).aarch64.rpm",
               "b01278c5cc50cd12b6a828c78417868c30dede086280d519141ff2f1728dd250", "compat.rpm")
]

dependencies = []

script = raw"""
apk add rpm2cpio
rpm2cpio compat.rpm | cpio -idmv

mkdir -p ${libdir}

mv usr/local/cuda-*/compat/* ${libdir}
"""

init_block = """
global version = $(repr(version))
"""

products = [
    LibraryProduct("libcuda", :libcuda;
                   dont_dlopen=true),
    LibraryProduct("libnvidia-ptxjitcompiler", :libnvidia_ptxjitcompiler;
                   dont_dlopen=true),
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

if should_build_platform("x86_64-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_x86, script,
                   [Platform("x86_64", "linux")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true, init_block)
end

if should_build_platform("powerpc64le-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_ppc64le, script,
                   [Platform("powerpc64le", "linux")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true, init_block)
end

if should_build_platform("aarch64-linux-gnu")
    build_tarballs(ARGS, name, version, sources_linux_aarch64, script,
                   [Platform("aarch64", "linux")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true, init_block)
end
