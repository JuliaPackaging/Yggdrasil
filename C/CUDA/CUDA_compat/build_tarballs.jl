# CUDA forward compatibility package as taken from the datacenter driver
#
# - https://docs.nvidia.com/deploy/cuda-compatibility/index.html#forward-compatibility-title
# - https://docs.nvidia.com/datacenter/tesla/index.html
# - https://www.nvidia.com/Download/index.aspx

using BinaryBuilder, Pkg

include("../../../fancy_toys.jl")

name = "CUDA_compat"
version = v"11.7"

cuda_version = "$(version.major)-$(version.minor)"
driver_version = "515.43.04"
build = 1

sources_linux_x86 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-compat-$(cuda_version)-$(driver_version)-$(build).x86_64.rpm",
               "89e7e27f996aab8b55d6809c8f99003984d69373a17e6c00ba38a1c174e9cf2b", "compat.rpm")
]
sources_linux_ppc64le = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/ppc64le/cuda-compat-$(cuda_version)-$(driver_version)-$(build).ppc64le.rpm",
               "c54a037018f83af7959b6146f5373abb7d46acd20049f80872b431f244fa16e5", "compat.rpm")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/sbsa/cuda-compat-$(cuda_version)-$(driver_version)-$(build).aarch64.rpm",
               "536cc7f3afcef80203a60c2c996effe555c38ee105557c925331eebf64060e7c", "compat.rpm")
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
