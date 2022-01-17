# CUDA forward compatibility package as taken from the datacenter driver
#
# - https://docs.nvidia.com/deploy/cuda-compatibility/index.html#forward-compatibility-title
# - https://docs.nvidia.com/datacenter/tesla/index.html
# - https://www.nvidia.com/Download/index.aspx

using BinaryBuilder, Pkg

include("../../../fancy_toys.jl")

name = "CUDA_compat"
version = v"11.6"

cuda_version = "$(version.major)-$(version.minor)"
driver_version = "510.39.01"
build = 1

sources_linux_x86 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-compat-$(cuda_version)-$(driver_version)-$(build).x86_64.rpm",
               "348bb6cd66042bd90bc58f7dd909962c3bc9c3eb7a4ef75aa3178aad9fc00d5a", "compat.rpm")
]
sources_linux_ppc64le = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/ppc64le/cuda-compat-$(cuda_version)-$(driver_version)-$(build).ppc64le.rpm",
               "7407dec3754ac416f6e10b5448756c463e9ab068f588bd30afbfc8fd600c3b45", "compat.rpm")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/sbsa/cuda-compat-$(cuda_version)-$(driver_version)-$(build).aarch64.rpm",
               "7d8eacda7955677839694ffb02f6d1444e2c66a0ff68327e5a82d2f0d8d994ac", "compat.rpm")
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
