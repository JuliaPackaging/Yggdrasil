# CUDA forward compatibility package as taken from the datacenter driver
#
# - https://docs.nvidia.com/deploy/cuda-compatibility/index.html#forward-compatibility-title
# - https://docs.nvidia.com/datacenter/tesla/index.html
# - https://www.nvidia.com/Download/index.aspx

using BinaryBuilder, Pkg

include("../../../fancy_toys.jl")

name = "CUDA_compat"
version = v"11.5.50"

cuda_version = "$(version.major)-$(version.minor)"
driver_version = "495.29.05"
build = 1

sources_linux_x86 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-compat-$(cuda_version)-$(driver_version)-$(build).x86_64.rpm",
               "d8eabf75a651266a706c9b00edb75ce7f4097dd1a9185c20ecfaf5375e06ebf9", "compat.rpm")
]
sources_linux_ppc64le = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/ppc64le/cuda-compat-$(cuda_version)-$(driver_version)-$(build).ppc64le.rpm",
               "6a830001cd0ae318b2b0f5b1970ecb799f42b311d6483fff58b332073e19e647", "compat.rpm")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/sbsa/cuda-compat-$(cuda_version)-$(driver_version)-$(build).aarch64.rpm",
               "6aebc19cdab34f36b914875a45bda2ce398485a95e156b37ee7b2699e4bd4276", "compat.rpm")
]

dependencies = []

script = raw"""
apk add rpm2cpio
rpm2cpio compat.rpm | cpio -idmv

mkdir -p ${libdir}

mv usr/local/cuda-*/compat/* ${libdir}
"""

products = [
    LibraryProduct("libcuda", :libcuda),
    LibraryProduct("libnvidia-ptxjitcompiler", :libnvidia_ptxjitcompiler),
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

if should_build_platform("x86_64-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_x86, script,
                   [Platform("x86_64", "linux")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true)
end

if should_build_platform("powerpc64le-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_ppc64le, script,
                   [Platform("powerpc64le", "linux")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true)
end

if should_build_platform("aarch64-linux-gnu")
    build_tarballs(ARGS, name, version, sources_linux_aarch64, script,
                   [Platform("aarch64", "linux")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true)
end
