# CUDA forward compatibility driver
#
# - https://docs.nvidia.com/deploy/cuda-compatibility/index.html#forward-compatibility-title
# - https://docs.nvidia.com/datacenter/tesla/index.html
# - https://www.nvidia.com/Download/index.aspx

using BinaryBuilder, Pkg

include("../../../fancy_toys.jl")

name = "CUDA_Driver"
version = v"0.10.4"

cuda_version = v"12.6"
cuda_version_str = "$(cuda_version.major)-$(cuda_version.minor)"
driver_version_str = "560.35.05"
build = 1

sources_linux_x86 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-compat-$(cuda_version_str)-$(driver_version_str)-$(build).el8.x86_64.rpm",
               "0c5f6de2b07ca6f0526dab89200aac8bc2fbe218572175be278f40f6a6a0693c", "compat.rpm")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/sbsa/cuda-compat-$(cuda_version_str)-$(driver_version_str)-$(build).el8.aarch64.rpm",
               "eaa58bf35d500ea447ef6dfc3ee450e495f3508fb8cec118f39ca274c059205e", "compat.rpm")
]

dependencies = []

script = raw"""
    apk update
    apk add rpm2cpio
    rpm2cpio compat.rpm | cpio -idmv

    mkdir -p ${libdir}

    mv usr/local/cuda-*/compat/* ${libdir}
"""

# CUDA_Driver_jll provides libcuda_compat, but we can't always use that driver: It requires
# specific hardware, and a compatible operating system. So we don't just dlopen the library,
# but instead check during __init__ if we can, and dlopen either the system driver or the
# compatible one from this JLL.
#
# Ordinarily, we'd put this logic in a package that depends on CUDA_Driver_jll (e.g.
# CUDA_Driver.jl), but that complicates depending on it from other JLLs (like
# CUDA_Runtime_jll). This will also simplify moving the logic into CUDA_Runtime_jll, which
# we will have to at some point (because its pkg hooks shouldn't depend on CUDA_Driver_jll).
init_block = read(joinpath(@__DIR__, "init.jl"), String)
init_block = map(eachline(IOBuffer(init_block))) do line
        # indent non-empty lines
        (isempty(line) ? "" : "    ") * line * "\n"
    end |> join

products = [
    LibraryProduct("libcuda", :libcuda_compat;                            dont_dlopen=true),
    LibraryProduct("libcudadebugger", :libcuda_debugger;                  dont_dlopen=true),
    LibraryProduct("libnvidia-nvvm", :libnvidia_nvvm;                     dont_dlopen=true),
    LibraryProduct("libnvidia-ptxjitcompiler", :libnvidia_ptxjitcompiler; dont_dlopen=true),
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

if should_build_platform("x86_64-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_x86, script,
                   [Platform("x86_64", "linux")], products, dependencies;
                   skip_audit=true, init_block)
end

if should_build_platform("aarch64-linux-gnu")
    build_tarballs(ARGS, name, version, sources_linux_aarch64, script,
                   [Platform("aarch64", "linux")], products, dependencies;
                   skip_audit=true, init_block)
end
